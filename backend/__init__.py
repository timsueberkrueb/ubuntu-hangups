# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'
__version__ = '0.1'

import pyotherside
import mimetypes
import asyncio
import threading

mimetypes.knownfiles = []  # Workaround for PermissionError
import os
import hangups
from hangups.ui.utils import get_conv_name
from hangups.ui.notify import Notifier
import hangups.schemas

import requests.adapters
from .utils import get_conv_icon, get_message_timestr, get_message_html, get_unread_messages_count
from . import model

try:
    APP_ID = os.environ['APP_ID']
    APP_PKGNAME = APP_ID.split('_')[0]
    app_data_path = os.environ['XDG_DATA_HOME'] + '/' + APP_PKGNAME + '/'
except KeyError:
    app_data_path = './'

if not os.path.exists(app_data_path):
    os.makedirs(app_data_path)

import backend.settings as settings

settings.load(app_data_path)

import backend.cache as cache

cache.initialize(app_data_path + 'cache/')

disable_notifier = True
refresh_token_filename = app_data_path + 'refresh_token.txt'
conv_controllers = {}
last_newly_created_conv_id = None


class ConversationController:
    def __init__(self, conv):
        self.conv = conv
        self.title = ''

        self.loading = False
        self.first_loaded = False
        self.typing_statuses = {}
        self.status_message = ""

        conv.on_event.add_observer(self.on_event)
        conv.on_watermark_notification.add_observer(self.on_watermark_notification)
        conv.on_typing.add_observer(self.on_typing)
        print(conv.events)
        for event in conv.events:
            self.on_event(event)

        # Start timer routine
        threading.Timer(settings.get('check_routine_timeout'), self.check_routine).start()

    def check_routine(self):
        print("Running check routine of ", self.conv.id_)
        call_threadsafe(self.update_online_status)
        # Start new timer
        threading.Timer(settings.get('check_routine_timeout'), self.check_routine).start()

    def handle_message(self, conv_event, user, set_unread, insert_mode="bottom"):
        message = get_message_html(conv_event.segments)
        pyotherside.send('add-conversation-message',
                         self.conv.id_,
                         {
                             "text": message,
                             "attachments": [{'url': cache.get_image_cached(a) if settings.get('cache_images') else a}
                                             for a in conv_event.attachments],
                             "user_is_self": user.is_self,
                             "username": user.full_name,
                             "time": get_message_timestr(conv_event.timestamp)
                         },
                         insert_mode)

    def handle_rename(self, conv_event, user):
        self.set_title()

    def handle_membership_change(self, conv_event, user):
        self.set_title()
        users = model.get_conv_users(self.conv)
        pyotherside.send('set-conversation-users', self.conv.id_, users)

    def on_event(self, conv_event, set_title=True, set_unread=True):
        user = self.conv.get_user(conv_event.user_id)

        if isinstance(conv_event, hangups.ChatMessageEvent):
            self.handle_message(conv_event, user, set_unread=set_unread)
        elif isinstance(conv_event, hangups.RenameEvent):
            self.handle_rename(conv_event, user)
        elif isinstance(conv_event, hangups.MembershipChangeEvent):
            self.handle_membership_change(conv_event, user)

        # Update the title in case unread count or conversation name changed.
        if set_title:
            self.set_title()

    def on_watermark_notification(self, watermark_notification):
        print("watermark_notification", self.conv.latest_read_timestamp)

    def on_typing(self, typing_message):
        self.typing_statuses[typing_message.user_id] = typing_message.status
        self.update_typing()

    def update_typing(self):
        global user_list
        typers = [self.conv.get_user(user_id).first_name
                  for user_id, status in self.typing_statuses.items()
                  if status == hangups.TypingStatus.TYPING and user_id != user_list._self_user.id_]
        if len(typers) > 0:
            typing_message = '{} {} typing...'.format(
                ', '.join(sorted(typers)),
                'is' if len(typers) == 1 else 'are'
            )
        else:
            typing_message = ''
        if self.status_message != typing_message:
            self.status_message = typing_message
            pyotherside.send('set-conversation-status', self.conv.id_, typing_message, sorted(typers))

    def set_title(self, future=None):
        title = get_conv_name(self.conv, show_unread=False,
                              truncate=True)
        pyotherside.send('set-conversation-title', self.conv.id_, title, get_unread_messages_count(self.conv),
                         self.status_message)
        if future:
            future.result()

    def send_message(self, text, image_file=None):
        global loop
        segments = hangups.ChatMessageSegment.from_str(text)
        asyncio.async(
            self.conv.send_message(segments, image_file=image_file)
        ).add_done_callback(self.on_message_sent)

    def on_message_sent(self, future):
        global loop
        try:
            future.result()
            asyncio.async(client.setfocus(self.conv.id_))
            print('Message sent successful')
        except hangups.NetworkError:
            print('Failed to send message')

    def load_more(self):
        asyncio.async(self._load_more())

    def set_typing(self, typing):
        global client
        if typing == "typing":
            t = hangups.schemas.TypingStatus.TYPING
        elif typing == "paused":
            t = hangups.schemas.TypingStatus.PAUSED
        else:
            t = hangups.schemas.TypingStatus.STOPPED

        asyncio.async(client.settyping(self.conv.id_, t))

    @asyncio.coroutine
    def _load_more(self):
        if not self.loading and not self.first_loaded:
            self.loading = True
            try:
                conv_events = yield from self.conv.get_events(
                    self.conv.events[0].id_
                )
                for conv_event in reversed(conv_events):
                    if (isinstance(conv_event, hangups.ChatMessageEvent)):
                        user = self.conv.get_user(conv_event.user_id)
                        self.handle_message(conv_event, user, False, "top")
            except (IndexError, hangups.NetworkError):
                conv_events = []
            if len(conv_events) == 0:
                self.first_loaded = True
                pyotherside.send('on-first-message-loaded', self.conv.id_)
            self.loading = False

    def on_entered(self):
        global client
        # Set the client as active.
        future = asyncio.async(client.set_active())
        future.add_done_callback(lambda future: future.result())

        future = asyncio.async(self.conv.update_read_timestamp())
        future.add_done_callback(lambda future: future.result())

        asyncio.async(client.setfocus(self.conv.id_))

    def on_leave(self):
        self.set_title()

    def on_messages_read(self):
        # Mark the newest event as read.
        future = asyncio.async(self.conv.update_read_timestamp())

    def add_users(self, users):
        global client
        asyncio.async(client.adduser(self.conv.id_, users))

    def delete(self):
        global client
        users_len = len(self.conv.users)
        if users_len == 2:
            asyncio.async(client.deleteconversation(self.conv.id_)).add_done_callback(self.on_deleted)
        elif users_len > 2:
            asyncio.async(client.removeuser(self.conv.id_)).add_done_callback(self.on_deleted)

    def on_deleted(self, future):
        pyotherside.send('delete-conversation', self.conv.id_)
        self.conv.on_event.remove_observer(self.on_event)
        self.conv.on_watermark_notification.remove_observer(self.on_watermark_notification)
        del conv_controllers[self.conv.id_]
        future.result()

    def set_quiet(self, quiet):
        level = hangups.schemas.ClientNotificationLevel.QUIET if quiet else hangups.schemas.ClientNotificationLevel.RING
        asyncio.async(self.conv.set_notification_level(level)).add_done_callback(self.on_quiet_set)

    def on_quiet_set(self, future):
        pyotherside.send('set-conversation-is-quiet', self.conv.id_, self.conv.is_quiet)
        future.result()

    def rename(self, name):
        global client
        asyncio.async(client.setchatname(self.conv.id_, name))

    def update_online_status(self):
        if len(self.conv.users) == 2:
            for user in self.conv.users:
                if not user.is_self:
                    asyncio.async(client.querypresence(user.id_.chat_id)).add_done_callback(self.online_status_updated)
                    break

    def online_status_updated(self, future):
        res = future.result()
        pyotherside.send('set-conversation-online', self.conv.id_, dict(future.result())["presence_result"][0]["presence"]['available'])


def get_login_url():
    return hangups.auth.OAUTH2_LOGIN_URL


def auth_with_code(refresh_token, access_token):
    def get_code_f():
        return refresh_token

    try:
        hangups.auth._save_oauth2_refresh_token(refresh_token_filename, refresh_token)
        #access_token = hangups.auth._auth_with_code(get_code_f, refresh_token_filename)
        print('Authentication successful')
        #cookies = hangups.auth._get_session_cookies(access_token)
        #load(cookies)
        auth_with_token()
    except hangups.GoogleAuthError as e:
        print('Failed to authenticate using refresh token: {}'.format(e))


def auth_with_token():
    try:
        print('Authenticating with refresh token')
        access_token = hangups.auth._auth_with_refresh_token(refresh_token_filename)
        print('Authentication successful')
        cookies = hangups.auth._get_session_cookies(access_token)
        load(cookies)
    except hangups.GoogleAuthError as e:
        print('Failed to authenticate using refresh token: {}'.format(e))
        print('Authenticating with authorization code')
        pyotherside.send('show-login-page')


@asyncio.coroutine
def on_connect(initial_data):
    """Handle connecting for the first time."""
    global client, disable_notifier, conv_list, user_list

    print("Building user list")
    user_list = yield from hangups.build_user_list(
        client, initial_data
    )

    print("Adding contacts")
    for user in sorted(user_list.get_all(), key=lambda u: u.full_name):
        user_data = {
            "id_": user.id_.chat_id,
            "name": user.full_name,
            "first_name": user.first_name,
            "photo_url": "https:" + user.photo_url if user.photo_url else None,
            "emails": user.emails,
        }
        if not user.is_self:
            pyotherside.send('add-contact', user_data)

    print("Creating conversations list")
    conv_list = hangups.ConversationList(
        client, initial_data.conversation_states, user_list,
        initial_data.sync_timestamp
    )
    print("Added conversations oveserver")
    conv_list.on_event.add_observer(on_event)
    if not disable_notifier:
        notifier = Notifier(conv_list)

    convs = sorted(conv_list.get_all(), reverse=True,
                   key=lambda c: c.last_modified)

    print("Showing conversations")
    for conv in convs:
        conv_data = {
            "title": get_conv_name(conv),
            "status_message": "",
            "icon": get_conv_icon(conv),
            "id_": conv.id_,
            "first_message_loaded": False,
            "unread_count": get_unread_messages_count(conv),
            "is_quiet": conv.is_quiet,
            "online": False,
            "users": [{
                          "id_": user.id_[0],
                          "full_name": user.full_name,
                          "first_name": user.first_name,
                          "photo_url": "https:" + user.photo_url if user.photo_url else None,
                          "emails": user.emails,
                          "is_self": user.is_self
                      } for user in conv.users]
        }
        pyotherside.send('add-conversation', conv_data)
        ctrl = ConversationController(conv)
        ctrl.update_online_status()
        conv_controllers[conv.id_] = ctrl

    print("Setting presence")
    set_client_presence(True)

    pyotherside.send('show-conversations-page')


def on_event(conv_event):
    global conv_list, conv_controllers
    conv = conv_list.get(conv_event.conversation_id)
    user = conv.get_user(conv_event.user_id)
    # is this a new conversation?
    if conv_event.conversation_id not in conv_controllers.keys():
        convs = sorted(conv_list.get_all(), reverse=True,
                       key=lambda c: c.last_modified)
        for conv in convs:
            if conv.id_ == conv_event.conversation_id:
                break
        conv_data = {
            "title": get_conv_name(conv),
            "status_message": "",
            "icon": get_conv_icon(conv),
            "id_": conv.id_,
            "first_message_loaded": False,
            "unread_count": get_unread_messages_count(conv),
            "is_quiet": conv.is_quiet,
            "online": False,
            "users": [{
                          "id_": user.id_[0],
                          "full_name": user.full_name,
                          "first_name": user.first_name,
                          "photo_url": "https:" + user.photo_url if user.photo_url else None,
                          "emails": user.emails,
                          "is_self": user.is_self
                      } for user in conv.users]
        }
        pyotherside.send('add-conversation', conv_data, True)
        ctrl = ConversationController(conv)
        ctrl.update_online_status()
        conv_controllers[conv.id_] = ctrl
        pyotherside.send('move-conversation-to-top', conv_event.conversation_id)
    else:
        pyotherside.send('move-conversation-to-top', conv_event.conversation_id)


def set_client_presence(online):
    print("/!\ FIXME: presence wasn't set")
    return
    # Currently disabled because of error:
    # hangups.exceptions.NetworkError: Unexpected status: ERROR_INVALID_REQUEST
    global client
    try:
        asyncio.async(client.setpresence(online))
    except hangups.exceptions.NetworkError as e:
        print("Failed to set presence:", str(e))

def entered_conversation(conv_id):
    call_threadsafe(conv_controllers[conv_id].on_entered)


def left_conversation(conv_id):
    call_threadsafe(conv_controllers[conv_id].on_leave)


def read_messages(conv_id):
    call_threadsafe(conv_controllers[conv_id].on_messages_read)


def add_users(conv_id, users):
    call_threadsafe(conv_controllers[conv_id].add_users, users)


def delete_conversation(conv_id):
    call_threadsafe(conv_controllers[conv_id].delete)


def send_message(conv_id, text):
    call_threadsafe(conv_controllers[conv_id].send_message, text)


def create_conversation(users):
    call_threadsafe(_create_conversation, users)


def _create_conversation(users):
    global client
    future = asyncio.async(client.createconversation(users))
    future.add_done_callback(on_conversation_created)


def on_conversation_created(future):
    global conv_list
    conv_id = future.result()['conversation']['id']['id']
    pyotherside.send('on-new-conversation-created', conv_id)


def send_new_conversation_welcome_message(conv_id, text):
    call_threadsafe(_send_new_conversation_welcome_message, conv_id, text)


def _send_new_conversation_welcome_message(conv_id, text):
    global last_newly_created_conv_id
    last_newly_created_conv_id = conv_id
    segments = hangups.ChatMessageSegment.from_str(text)
    asyncio.async(
        client.sendchatmessage(conv_id, [seg.serialize() for seg in segments])
    ).add_done_callback(on_new_conversation_welcome_message_sent)


def on_new_conversation_welcome_message_sent(future):
    global last_newly_created_conv_id
    pyotherside.send('clear-conversation-messages', last_newly_created_conv_id)


def send_image(conv_id, filename):
    filename = filename[filename.find("/home"):]
    image_file = open(filename, 'rb')
    call_threadsafe(conv_controllers[conv_id].send_message, "", image_file);


def load_more_messages(conv_id):
    call_threadsafe(conv_controllers[conv_id].load_more)


def set_typing(conv_id, typing):
    call_threadsafe(conv_controllers[conv_id].set_typing, typing)


def set_conversation_quiet(conv_id, quiet):
    call_threadsafe(conv_controllers[conv_id].set_quiet, quiet)


def rename_conversation(conv_id, name):
    call_threadsafe(conv_controllers[conv_id].rename, name)


def cache_get_image(url):
    return cache.get_image_cached(url)


def settings_get(key):
    return settings.get(key)


def settings_set(key, value):
    return settings.set(key, value)


def clear_cache():
    return cache.clear()


def run_asyncio_loop_in_thread(loop):
    asyncio.set_event_loop(loop)
    try:
        # Returns when the connection is closed.
        loop.run_until_complete(client.connect())
    finally:
        loop.close()


def call_threadsafe(callback, *args):
    global loop
    loop.call_soon_threadsafe(callback, *args)


def load(cookies):
    global client, loop
    print("Loading ...")
    print("Creating client ...")
    client = hangups.Client(cookies)
    print("Adding client observer")
    client.on_connect.add_observer(on_connect)

    loop = asyncio.get_event_loop()

    t = threading.Thread(target=run_asyncio_loop_in_thread, args=(loop,))
    t.start()


def start():
    # Authenticate and connect
    try:
        auth_with_token()
    except requests.exceptions.ConnectionError as e:
        error_title = e.args[0].args[0]
        error_description = e.args[0].args[1]
        pyotherside.send('show-network-error', "ConnectionError", error_title, str(error_description))


def on_quit():
    print("Exiting ...")
    print('Saving settings ...')
    settings.save()
    print("Setting presence")
    call_threadsafe(set_client_presence, False)
    client.disconnect()
    loop.close()


pyotherside.atexit(on_quit)
