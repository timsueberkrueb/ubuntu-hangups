# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'


import json
import os.path


default_settings = {
    'cache_images': True,
}
settings = default_settings
filename = "settings.json"
unsaved_changes = False


def save(force=False):
    global settings, filename, unsaved_changes
    if unsaved_changes or force:
        with open(filename, 'w') as file:
            file.write(json.dumps(settings, sort_keys=True, indent=4))
            unsaved_changes = False


def load(path='settings.json'):
    global settings, filename
    filename = path + 'settings.json'

    if not os.path.isfile(filename):
        save(force=True)
        return

    with open(filename, 'r') as file:
        settings = json.loads(file.read())


def get(key):
    return settings[key]


def set(key, value):
    global settings, unsaved_changes
    if settings[key] != value:
        unsaved_changes = True
        settings[key] = value
