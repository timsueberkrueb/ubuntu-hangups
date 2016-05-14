# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'


import json
import os.path


default_settings = {
    'cache_images': True,
    'custom_chat_background': False,
    'load_stickers_on_start': True
}
settings = default_settings
filename = "settings.json"


def save():
    global settings, filename
    with open(filename, 'w') as file:
        file.write(json.dumps(settings, sort_keys=True, indent=4))
        unsaved_changes = False


def load(path='settings.json'):
    global settings, filename
    filename = path + 'settings.json'

    if not os.path.isfile(filename):
        save()
        return

    with open(filename, 'r') as file:
        settings.update(json.loads(file.read()))


def get(key):
    return settings[key]


def set(key, value):
    global settings
    if settings[key] != value:
        settings[key] = value
        save()
