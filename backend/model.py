# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'


def get_conv_users(conv):
    return [{
              "id_": user.id_[0],
              "full_name": user.full_name,
              "first_name": user.first_name,
              "photo_url": "https:" + user.photo_url if user.photo_url else None,
              "emails": user.emails,
              "is_self": user.is_self
            } for user in conv.users]
