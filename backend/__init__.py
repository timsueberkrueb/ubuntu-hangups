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
from .utils import get_conv_icon, get_message_timestr, get_message_html, get_unread_messages_count

try:
    APP_ID = os.environ['APP_ID']
    APP_PKGNAME = APP_ID.split('_')[0]
    app_data_path = os.environ['XDG_DATA_HOME'] + '/' + APP_PKGNAME + '/'
except KeyError:
    app_data_path = './'

import backend.settings as settings

settings.load(app_data_path)

import backend.cache as cache

cache.initialize(app_data_path + 'cache/')

disable_notifier = True
refresh_token_filename = app_data_path + 'refresh_token.txt'
conv_controllers = {}


class ConversationController:
    def __init__(self, conv):
        self.conv = conv
        self.title = ''

        self.loading = False
        self.first_loaded = False

        conv.on_event.add_observer(self.on_event)
        print(conv.events)
        for event in conv.events:
            self.on_event(event)

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

    def set_title(self, future=None):
        title = get_conv_name(self.conv, show_unread=False,
                              truncate=True)
        pyotherside.send('set-conversation-title', self.conv.id_, title, get_unread_messages_count(self.conv))
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
            print('Message sent successful')
        except hangups.NetworkError:
            print('Failed to send message')

    def load_more(self):
        asyncio.async(self._load_more())

    @asyncio.coroutine
    def _load_more(self):
        if not self.loading and not self.first_loaded:
            self.loading = True
            try:
                conv_events = yield from self.conv.get_events(
                    self.conv.events[0].id_
                )
                for conv_event in conv_events:
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

        # Mark the newest event as read.
        future = asyncio.async(self.conv.update_read_timestamp())
        future.add_done_callback(self.set_title)


def get_login_url():
    return hangups.auth.OAUTH2_LOGIN_URL


def auth_with_code(code):
    def get_code_f():
        return code

    try:
        access_token = hangups.auth._auth_with_code(get_code_f, refresh_token_filename)
        print('Authentication successful')
        cookies = hangups.auth._get_session_cookies(access_token)
        load(cookies)
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
            "icon": get_conv_icon(conv),
            "id_": conv.id_,
            "first_message_loaded": False,
            "unread_count": get_unread_messages_count(conv),
            "is_quiet": conv.is_quiet,
            "users": [{
                          "id_": user.id_,
                          "full_name": user.full_name,
                          "first_name": user.first_name,
                          "photo_url": "https:" + user.photo_url if user.photo_url else None,
                          "emails": user.emails,
                          "is_self": user.is_self
                      } for user in conv.users]
        }
        pyotherside.send('add-conversation', conv_data)
        ctrl = ConversationController(conv)
        conv_controllers[conv.id_] = ctrl

    pyotherside.send('show-conversations-page')


def on_event(conv_event):
    global conv_list
    conv = conv_list.get(conv_event.conversation_id)
    user = conv.get_user(conv_event.user_id)
    print(conv, user)
    pyotherside.send('move-conversation-to-top', conv_event.conversation_id)


def entered_conversation(conv_id):
    call_threadsafe(conv_controllers[conv_id].on_entered)


def send_message(conv_id, text):
    call_threadsafe(conv_controllers[conv_id].send_message, text)


def send_image(conv_id, filename):
    filename = filename[filename.find("/home"):]
    image_file = open(filename, 'rb')
    call_threadsafe(conv_controllers[conv_id].send_message, "", image_file);


def load_more_messages(conv_id):
    call_threadsafe(conv_controllers[conv_id].load_more)


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
    auth_with_token()


def on_quit():
    print("Exiting ...")
    print('Saving settings ...')
    settings.save()
    client.disconnect()
    loop.close()


pyotherside.atexit(on_quit)