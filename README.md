<h1><img src="https://raw.githubusercontent.com/tim-sueberkrueb/ubuntu-hangups/master/ubuntu-hangups.png" width="64"> Ubuntu Hangups</h1>


An inofficial Google Hangouts client for Ubuntu Touch

This application uses <a href='https://github.com/tdryer'>Tom Dryer</a>'s inofficial Google Hangouts Python library <a href='https://github.com/tdryer/hangups'>Hangups</a>.
Powered by <a href='https://github.com/thp'>Thomas Perl's</a> <a href='https://github.com/thp/pyotherside'>PyOtherSide</a>

## Third-party software
Ubuntu Hangups includes the following third-party software:
* Notification sound (media/notification-sound.wav) by TheGertz is licensed under the Creative Commons 0 License (cc-0, http://creativecommons.org/publicdomain/zero/1.0/): https://www.freesound.org/people/TheGertz/sounds/235911/
* Send icon from Font Awesome (media/fontawesome-paper-plane-blue.png): http://fortawesome.github.io/Font-Awesome/icons/
* The loading animation (media/loading-animation.gif) by Fabian Süberkrüb is licensed under the Creative Commons Attribution License 4.0 (cc-by, https://creativecommons.org/licenses/by/4.0/)

The application icon was created using <a href='https://github.com/halfsail'>Kevin Feyder</a>'s <a href='https://github.com/halfsail/Ubuntu-UI-Toolkit#suru-icon-template-kit'>Suru Icon Template kit</a>

## Translations
Ubuntu Hangups uses the gettext localization system (i18n). You can create new translations using the i18n editor of your choice (e.g. Poedit) Please help me translating this app and send me a pull request or contact me via Gitter!

## Contact
Contact me via Gitter: https://gitter.im/tim-sueberkrueb/

# Installation on Ubuntu

## Dependencies
* ubuntu-ui-toolkit 1.2
* pyotherside (https://thp.io/2011/pyotherside/)
* hangups (https://github.com/tdryer/hangups)
  * aiohttp
  * purplex
  * requests
  * reparser
* pymmh3 (or another python MurmurHash3 implementation, e.g. mmh3)

## Install and run on Ubuntu Desktop

Clone ubuntu-hangups

```
git clone https://github.com/tim-sueberkrueb/ubuntu-hangups
```

### Installation
* Install PyOtherSide

 ```
  sudo apt-get install pyotherside
  ```
* Download and install hangups

  ```
  pip3 install hangups
  ```
* Install a MurmurHash3 implementation

  ```
  sudo pip3 install mmh3
  ```
* Make sure that all python dependencies (see above) are installed.

### Run
Inside the ubuntu-hangups directory run:

```
qmlscene Main.qml
```


## Build for Ubuntu Touch
* Make sure you have the Ubuntu SDK installed

  https://developer.ubuntu.com/en/start/ubuntu-sdk/installing-the-sdk/
* Run from the ubuntu-hangups directory:
  
  ```
  python3 get_libs.py
  ```
* Download the sources of the following python packages and include them in lib/py/:
  * aiohttp (https://github.com/KeepSafe/aiohttp)
  * purplex (https://github.com/mtomwing/purplex)
  * requests (https://github.com/kennethreitz/requests)
  * pymmh3.py (https://github.com/wc-duck/pymmh3)
  * reparser (https://github.com/xmikos/reparser)

### Build and run
* Open ubuntu-hangups.qmlproject with the Ubuntu-SDK, add the appropriate build kit and run!


## Copyright and License
(C) Copyright 2015 by Tim Süberkrüb

This application is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

See LICENSE for more information.

This application is not endorsed by or affiliated with Ubuntu or Canonical. Ubuntu and Canonical are registered trademarks of Canonical Ltd.
