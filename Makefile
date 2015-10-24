# More information: https://wiki.ubuntu.com/Touch/Testing
#
# Notes for autopilot tests:
# ---------------------------------------------------------------
# In order to run autopilot tests:
# sudo apt-add-repository ppa:autopilot/ppa
# sudo apt-get update
# sudo apt-get install python-autopilot autopilot-qt
#
# Notes for translations:
# ---------------------------------------------------------------
# In order to create translation files manually:
# 1) run make once to create and update the po/ubuntu-hangups.pot
# 2) copy the template file and set the name to the language you want to
#    translate to:   cp po/ubuntu-hangups.pot po/en.po
# 3) edit the po file
# 4) run make build-translations to build the translation files
#
# Steps 1) and 4) are automatically executed by QtCreator
#################################################################

#APP_ID needs to match the "name" field of the click manifest
APP_ID=ubuntu-hangups.timsueberkrueb

#provides a way for the IDE to set a specific target folder for the translations
TRANSLATION_ROOT=.

MO_FILES=$(shell for infile in `find po -name "*.po"`; do basename -s .po $$infile | awk '{print "$(TRANSLATION_ROOT)/share/locale/" $$0 "/LC_MESSAGES/$(APP_ID).mo";}' ; done)
QMLJS_FILES=$(shell find . -name "*.qml" -o -name "*.js" | grep -v ./tests)

all: po/ubuntu-hangups.pot

autopilot:
	chmod +x tests/autopilot/run
	tests/autopilot/run

check:
	qmltestrunner -input tests/qml

#translation targets

build-translations: $(MO_FILES)

po/ubuntu-hangups.pot: $(QMLJS_FILES)
	mkdir -p $(CURDIR)/po && xgettext -o po/ubuntu-hangups.pot --qt --c++ --add-comments=TRANSLATORS --keyword=tr --keyword=tr:1,2 $(QMLJS_FILES) --from-code=UTF-8

$(TRANSLATION_ROOT)/share/locale/%/LC_MESSAGES/$(APP_ID).mo: po/%.po
	mkdir -p $(TRANSLATION_ROOT)/share/locale/$*/LC_MESSAGES && msgfmt -o $(@) $(<)

