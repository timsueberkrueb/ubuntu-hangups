# -*- coding: utf-8 -*-
from _threading_local import local

__author__ = 'Tim Süberkrüb'
__version__ = '0.1'

import pyotherside
import mimetypes
import asyncio
import functools
import threading
import shutil

mimetypes.knownfiles = []  # Workaround for PermissionError
import os
import hangups
from hangups.ui.utils import get_conv_name
from hangups.ui.notify import Notifier
from hangups import hangouts_pb2
from hangups import pblite

import requests.adapters
from .utils import get_conv_icon, \
    get_message_timestr, \
    get_message_html,\
    get_unread_messages_count,\
    get_message_plain_text
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

        self.initial_messages_loaded = False
        self.loading = False
        self.first_loaded = False
        self.typing_statuses = {}
        self.status_message = ""

        self.current_local_id = 0

        conv.on_event.add_observer(self.on_event)
        conv.on_watermark_notification.add_observer(self.on_watermark_notification)
        conv.on_typing.add_observer(self.on_typing)
        for event in conv.events:
            self.on_event(event)

        # Load some more messages on start:
        asyncio.async(self._load_more(max_events=5))

        # Start timer routine
        threading.Timer(settings.get('check_routine_timeout'), self.check_routine).start()

    def load(self):
        def loaded(future):
            pyotherside.send('on-conversation-loaded', self.conv.id_)
        self.load_more(loaded)

    def check_routine(self):
        print("Running check routine of ", self.conv.id_)
        call_threadsafe(self.update_online_status)
        # Start new timer
        threading.Timer(settings.get('check_routine_timeout'), self.check_routine).start()

    def handle_message(self, conv_event, user, set_unread, insert_mode="bottom"):
        html = get_message_html(conv_event.segments)
        text = get_message_plain_text(conv_event.segments)
        pyotherside.send('add-conversation-message',
                         self.conv.id_,
                         model.get_message_model_data(
                             type="chat/message",
                             html=html,
                             text=text,
                             attachments=[{'url': cache.get_image_cached(a) if settings.get('cache_images') else a}
                                             for a in conv_event.attachments],
                             user_is_self=user.is_self,
                             username=user.full_name,
                             user_photo= "https:" + user.photo_url if user.photo_url else None,
                             time=get_message_timestr(conv_event.timestamp)
                         ),
                         insert_mode)

        self.set_title()

    def handle_rename(self, conv_event, user, insert_mode="bottom"):
        self.set_title()
        pyotherside.send('add-conversation-message',
                         self.conv.id_,
                         model.get_message_model_data(
                             type="chat/rename",
                             new_name=conv_event.new_name,
                             user_is_self=user.is_self,
                             username=user.full_name,
                             time=get_message_timestr(conv_event.timestamp)
                         ),
                         insert_mode)

    def handle_membership_change(self, conv_event, user, insert_mode="bottom"):
        self.set_title()
        users = model.get_conv_users(self.conv)
        pyotherside.send('set-conversation-users', self.conv.id_, users)
        event_users = [self.conv.get_user(user_id) for user_id in conv_event.participant_ids]
        names = [user.full_name for user in event_users]
        if conv_event.type_ == hangouts_pb2.MEMBERSHIP_CHANGE_TYPE_JOIN:
            for name in names:
                pyotherside.send('add-conversation-message',
                                 self.conv.id_,
                                 model.get_message_model_data(
                                     type="chat/add",
                                     name=name,
                                     user_is_self=user.is_self,
                                     username=user.full_name,
                                     time=get_message_timestr(conv_event.timestamp)
                                 ),
                                 insert_mode)
        else:
            for name in names:
                pyotherside.send('add-conversation-message',
                                 self.conv.id_,
                                 model.get_message_model_data(
                                     type="chat/leave",
                                     name=name,
                                     user_is_self=user.is_self,
                                     username=user.full_name,
                                     time=get_message_timestr(conv_event.timestamp)
                                 ),
                                 insert_mode)

    def on_event(self, conv_event, set_title=True, set_unread=True, insert_mode="bottom"):
        user = self.conv.get_user(conv_event.user_id)
        if isinstance(conv_event, hangups.ChatMessageEvent):
            self.handle_message(conv_event, user, set_unread=set_unread, insert_mode=insert_mode)
        elif isinstance(conv_event, hangups.RenameEvent):
            self.handle_rename(conv_event, user, insert_mode=insert_mode)
        elif isinstance(conv_event, hangups.MembershipChangeEvent):
            self.handle_membership_change(conv_event, user, insert_mode=insert_mode)


    def on_watermark_notification(self, watermark_notification):
        print("watermark_notification", self.conv.latest_read_timestamp)

    def on_typing(self, typing_message):
        self.typing_statuses[typing_message.user_id] = typing_message.status
        self.update_typing()

    def update_typing(self):
        global user_list
        typers = [self.conv.get_user(user_id).first_name
                  for user_id, status in self.typing_statuses.items()
                  if status == hangouts_pb2.TYPING_TYPE_STARTED and user_id != user_list._self_user.id_]
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

    def send_message(self, text, image_file=None, image_filename=None):
        global loop
        segments = hangups.ChatMessageSegment.from_str(text)
        local_id = self.current_local_id
        self.current_local_id += 1

        # Create dummy message
        pyotherside.send('add-conversation-message',
                 self.conv.id_,
                 model.get_message_model_data(
                     type="chat/message",
                     html=text,
                     text=text,
                     attachments=[{'url': image_filename}] if image_filename else [],
                     sent= False,
                     local_id=local_id,
                 ),
                 "bottom")

        asyncio.async(
            self.conv.send_message(segments, image_file=image_file)
        ).add_done_callback(functools.partial(self.on_message_sent, local_id=local_id))

    def on_message_sent(self, future, local_id=None):
        global loop, client
        try:
            pyotherside.send("remove-dummy-message", self.conv.id_, local_id)
            request = hangouts_pb2.SetFocusRequest(
                request_header=client.get_request_header(),
                conversation_id=hangouts_pb2.ConversationId(id=self.conv.id_),
                type=hangouts_pb2.FOCUS_TYPE_FOCUSED,
                timeout_secs=20,
            )
            asyncio.async(client.set_focus(request))
            print('Message sent successful')
        except hangups.NetworkError:
            print('Failed to send message')

    def load_more_messages(self):
        def callback(future=None):
            pyotherside.send('on-more-messages-loaded', self.conv.id_)
        self.load_more(callback)

    def load_more(self, callback=lambda future: future.result()):
        asyncio.async(self._load_more()).add_done_callback(callback)

    def set_typing(self, typing):
        global client
        if typing == "typing":
            t = hangouts_pb2.TYPING_TYPE_STARTED
        elif typing == "paused":
            t = hangouts_pb2.TYPING_TYPE_PAUSED
        else:
            t = hangouts_pb2.TYPING_TYPE_STOPPED

        request = hangouts_pb2.SetTypingRequest(
            request_header=client.get_request_header(),
            conversation_id=hangouts_pb2.ConversationId(id=self.conv.id_),
            type=t,
        )

        asyncio.async(client.set_typing(request))

    @asyncio.coroutine
    def _load_more(self, max_events=30):
        if not self.loading and not self.first_loaded:
            self.loading = True
            try:
                conv_events = yield from self.conv.get_events(
                    self.conv.events[0].id_,
                    max_events=max_events,
                )
                for conv_event in reversed(conv_events):
                    self.on_event(conv_event, insert_mode="top")
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

        request = hangouts_pb2.SetFocusRequest(
            request_header=client.get_request_header(),
            conversation_id=hangouts_pb2.ConversationId(id=self.conv.id_),
            type=hangouts_pb2.FOCUS_TYPE_FOCUSED,
            timeout_secs=20,
        )
        asyncio.async(client.set_focus(request))

    def on_leave(self):
        self.set_title()

    def on_messages_read(self):
        # Mark the newest event as read.
        future = asyncio.async(self.conv.update_read_timestamp())

    def add_users(self, users):
        global client

        request = hangouts_pb2.AddUserRequest(
            request_header=client.get_request_header(),
            invitee_id=[hangouts_pb2.InviteeID(gaia_id=chat_id)
                        for chat_id in users],
            event_request_header=hangouts_pb2.EventRequestHeader(
                conversation_id=hangouts_pb2.ConversationId(
                    id=self.conv.id_,
                ),
                client_generated_id=client.get_client_generated_id(),
                expected_otr=hangouts_pb2.OFF_THE_RECORD_STATUS_ON_THE_RECORD,
            ),
        )

        asyncio.async(client.add_user(request))

    def delete(self):
        global client
        asyncio.async(self.conv.leave()).add_done_callback(self.on_deleted)

    def on_deleted(self, future):
        pyotherside.send('delete-conversation', self.conv.id_)
        self.conv.on_event.remove_observer(self.on_event)
        self.conv.on_watermark_notification.remove_observer(self.on_watermark_notification)
        del conv_controllers[self.conv.id_]
        future.result()

    def set_quiet(self, quiet):
        level = hangouts_pb2.NOTIFICATION_LEVEL_QUIET if quiet else hangouts_pb2.NOTIFICATION_LEVEL_RING
        asyncio.async(self.conv.set_notification_level(level)).add_done_callback(self.on_quiet_set)
        pyotherside.send('set-conversation-is-quiet', self.conv.id_, quiet)

    def on_quiet_set(self, future):
        # Disabled as is_quiet doesn't always hold the right value
        #pyotherside.send('set-conversation-is-quiet', self.conv.id_, self.conv.is_quiet)
        pass

    def rename(self, name):
        global client
        asyncio.async(self.conv.rename(name))

    def update_online_status(self):
        global client
        if len(self.conv.users) == 2:
            for user in self.conv.users:
                if not user.is_self:

                    request = hangouts_pb2.QueryPresenceRequest(
                        request_header=client.get_request_header(),
                        participant_id=[hangouts_pb2.ParticipantId(gaia_id=user.id_.chat_id)],
                        field_mask=[hangouts_pb2.FIELD_MASK_REACHABLE,
                                    hangouts_pb2.FIELD_MASK_AVAILABLE,
                                    hangouts_pb2.FIELD_MASK_DEVICE],
                    )

                    asyncio.async(client.query_presence(request)).add_done_callback(self.online_status_updated)
                    break

    def online_status_updated(self, future):
        res = future.result()
        pyotherside.send('set-conversation-online', self.conv.id_, res.presence_result[0].presence.available)


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
        set_loading_status("authenticating")
        access_token = hangups.auth._auth_with_refresh_token(refresh_token_filename)
        print('Authentication successful')
        cookies = hangups.auth._get_session_cookies(access_token)
        load(cookies)
    except hangups.GoogleAuthError as e:
        print('Failed to authenticate using refresh token: {}'.format(e))
        print('Authenticating with authorization code')
        pyotherside.send('show-login-page')


@asyncio.coroutine
def on_connect():
    """Handle connecting for the first time."""
    global client, disable_notifier, conv_list, user_list

    print("Building conversation and user list")
    user_list, conv_list = (
        yield from hangups.build_user_conversation_list(client)
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

    print("Added conversations observer")
    conv_list.on_event.add_observer(on_event)
    if not disable_notifier:
        notifier = Notifier(conv_list)

    convs = sorted(conv_list.get_all(), reverse=True,
                   key=lambda c: c.last_modified)

    print("Showing conversations")
    for conv in convs:
        conv_data = model.get_conv_data(conv)
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
        conv_data = model.get_conv_data(conv)
        pyotherside.send('add-conversation', conv_data, True)
        ctrl = ConversationController(conv)
        ctrl.update_online_status()
        conv_controllers[conv.id_] = ctrl
        pyotherside.send('move-conversation-to-top', conv_event.conversation_id)
    else:
        pyotherside.send('move-conversation-to-top', conv_event.conversation_id)


def set_client_presence(online):
    print("Trying to set presence ...")
    global client
    try:
        pass
        #asyncio.async(client.set_presence(online))
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
    is_group = len(users) > 1
    request = hangouts_pb2.CreateConversationRequest(
        request_header=client.get_request_header(),
        type=(hangouts_pb2.CONVERSATION_TYPE_GROUP if is_group else
              hangouts_pb2.CONVERSATION_TYPE_ONE_TO_ONE),
        client_generated_id=client.get_client_generated_id(),
        invitee_id=[hangouts_pb2.InviteeID(gaia_id=chat_id)
                    for chat_id in users],
    )

    future = asyncio.async(client.create_conversation(request))
    future.add_done_callback(on_conversation_created)


def on_conversation_created(future):
    global conv_list
    conv_id = future.result().conversation.conversation_id.id
    pyotherside.send('on-new-conversation-created', conv_id)


def send_new_conversation_welcome_message(conv_id, text):
    call_threadsafe(_send_new_conversation_welcome_message, conv_id, text)


def _send_new_conversation_welcome_message(conv_id, text):
    global last_newly_created_conv_id
    global client
    last_newly_created_conv_id = conv_id
    segments = hangups.ChatMessageSegment.from_str(text)

    request = hangouts_pb2.SendChatMessageRequest(
        request_header=client.get_request_header(),
        message_content=hangouts_pb2.MessageContent(
            segment=[seg.serialize() for seg in segments],
        ),
        event_request_header=hangouts_pb2.EventRequestHeader(
            conversation_id=hangouts_pb2.ConversationId(
                 id=conv_id,
             ),
             client_generated_id=client.get_client_generated_id(),
             expected_otr=hangouts_pb2.OFF_THE_RECORD_STATUS_ON_THE_RECORD,
             delivery_medium=hangouts_pb2.DeliveryMedium(medium_type=hangouts_pb2.DELIVERY_MEDIUM_BABEL),
             event_type=hangouts_pb2.EVENT_TYPE_REGULAR_CHAT_MESSAGE,
         ),
    )
    asyncio.async(
        client.send_chat_message(request)
    ).add_done_callback(on_new_conversation_welcome_message_sent)


def on_new_conversation_welcome_message_sent(future):
    global last_newly_created_conv_id
    pyotherside.send('clear-conversation-messages', last_newly_created_conv_id)


def send_image(conv_id, filename):
    filename = filename[filename.find("/home"):]
    image_file = open(filename, 'rb')
    call_threadsafe(conv_controllers[conv_id].send_message, "", image_file, filename);


def load_more_messages(conv_id):
    call_threadsafe(conv_controllers[conv_id].load_more_messages)


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


def load_conversation(conv_id):
    call_threadsafe(conv_controllers[conv_id].load)


def set_loading_status(status):
    pyotherside.send('set-loading-status', status)


def set_chat_background(custom, filename=None):
    if custom:
        filename = filename[filename.find("/home"):]
        new_filename = app_data_path+'custom_chat_background'+os.path.splitext(filename)[1]
        shutil.copyfile(filename, new_filename)
        settings.set('custom_chat_background', new_filename)
    else:
        new_filename = False
        settings.set('custom_chat_background', False)
    pyotherside.send('on-chat-background-changed', new_filename)


def logout():
    os.remove(refresh_token_filename)


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
    set_loading_status("creatingClient")
    client = hangups.Client(cookies)
    print("Adding client observer")
    set_loading_status("addingObserver")
    client.on_connect.add_observer(on_connect)
    set_loading_status("loadingChats")
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
    print("Setting presence")
    call_threadsafe(set_client_presence, False)
    client.disconnect()
    loop.close()


pyotherside.atexit(on_quit)
