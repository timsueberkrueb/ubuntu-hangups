# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'


from hangups.ui.utils import get_conv_name
from backend.utils import get_conv_icon, get_unread_messages_count


def get_conv_users(conv):
    return [{
              "id_": user.id_[0],
              "full_name": user.full_name,
              "first_name": user.first_name,
              "photo_url": "https:" + user.photo_url if user.photo_url else None,
              "emails": user.emails,
              "is_self": user.is_self
            } for user in conv.users]


def get_conv_data(conv):
    return {
            "title": get_conv_name(conv),
            "status_message": "",
            "icon": get_conv_icon(conv),
            "id_": conv.id_,
            "first_message_loaded": False,
            "unread_count": get_unread_messages_count(conv),
            "is_quiet": conv.is_quiet,
            "online": False,
            "loaded": False,
            "users": [{
                          "id_": user.id_[0],
                          "full_name": user.full_name,
                          "first_name": user.first_name,
                          "photo_url": "https:" + user.photo_url if user.photo_url else None,
                          "emails": user.emails,
                          "is_self": user.is_self
                      } for user in conv.users]
           }

def get_message_model_data(type="chat/message", html="", text="", attachments=[], user_is_self=True, username="",
                           user_photo=None, time="", sent=True, local_id=-1, new_name="", name=""):
    return {
         "type": type,
         "html": html,
         "text": text,
         "attachments": attachments,
         "user_is_self": user_is_self,
         "username": username,
         "user_photo": user_photo,
         "time": time,
         "sent": sent,
         "local_id": local_id,
         "new_name": new_name,
         "name": name
    }