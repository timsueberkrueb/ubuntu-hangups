import QtQuick 2.4
import Ubuntu.Components 1.3

Page {
   title: i18n.tr("About")
   visible: false

   Flickable {
       id: flickable
       anchors.fill: parent
       contentHeight: col.childrenRect.height + units.gu(12)

       Column {
           id: col
           anchors.top: parent.top
           anchors.left: parent.left
           anchors.right: parent.right
           anchors.margins: units.gu(2)
           spacing: units.gu(1)

           Label {
                text: "Ubuntu Hangups"
                fontSize: "x-large"
           }

           FlexibleLabel {
                text: i18n.tr("Inofficial Google Hangouts client for Ubuntu Touch")
           }

           FlexibleLabel {
                text: i18n.tr("Source code available on <a href='https://github.com/tim-sueberkrueb/ubuntu-hangups'>GitHub</a>") + "<br/><br/>This application is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.<br/><br/> (C) Copyright 2015 by Tim Süberkrüb<br/>"
                onLinkActivated: Qt.openUrlExternally(link)
           }           

           FlexibleLabel {
               text: i18n.tr("Third-party Software")
               font.pixelSize: units.dp(24)
           }

           FlexibleLabel {
                text: i18n.tr("The application icon was created by <a href='http://samuelhewitt.com/'>Sam Hewitt</a>")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
                text: i18n.tr("This application uses <a href='https://github.com/tdryer'>Tom Dryer</a>'s inofficial Google Hangouts Python library <a href='https://github.com/tdryer/hangups'>Hangups</a>. Hangups is released under the MIT license.")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
                text: i18n.tr("Powered by <a href='https://github.com/thp'>Thomas Perl's</a> <a href='https://github.com/thp/pyotherside'>PyOtherSide</a>")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
               text: i18n.tr("The loading animation was created by %1.").arg("Fabian Süberkrüb")
           }

           FlexibleLabel {
                text: i18n.tr("The <a href='https://www.flickr.com/photos/zooboing/5127310748/'>default chat background</a> was created by <a href='https://www.flickr.com/photos/zooboing/'>Patrick Hoesly</a> and is licensed under the <a href='https://creativecommons.org/licenses/by/2.0/'>Creative Commons Attribution 2.0 Generic (CC BY 2.0) license.</a>")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
               text: i18n.tr("This application is not endorsed by or affiliated with Ubuntu or Canonical. Ubuntu and Canonical are registered trademarks of Canonical Ltd.")
           }

       }

   }

}
