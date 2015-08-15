# -*- coding: utf-8 -*-

__author__ = 'Tim Süberkrüb'


import urllib.request
import os
import glob
import shutil
# Loading MurmurHash3 lib
try:
    # try with a fast c-implementation ...
    import mmh3 as mmh3
except ImportError:
    # ... otherwise fallback to this code!
    import pymmh3 as mmh3


def initialize(p):
    global path
    global images_path
    global images
    path = p
    images_path = path + 'images/'

    # Create cache directory structure if necessary
    if not os.path.exists(path):
        os.makedirs(path)
    if not os.path.exists(images_path):
        os.makedirs(images_path)

def get_cached_images():
    global images_path
    return [f.split('/')[-1] for f in glob.glob(images_path + '*')]


def get_image_cache_name(url):
    extension = url.split('.')[-1]
    return 'img' + str(mmh3.hash(url.encode('utf-8'))) + '.' + extension.lower()


def is_image_cached(url):
    return get_image_cache_name(url) in get_cached_images()


def cache_image(url):
    urllib.request.urlretrieve (url, images_path + get_image_cache_name(url))


def get_image_cached(url, refresh=False):
    if not is_image_cached(url) or refresh:
        cache_image(url)
    return os.path.abspath(images_path + get_image_cache_name(url))


def clear():
    global path
    shutil.rmtree(path)
    initialize(path)
    return True