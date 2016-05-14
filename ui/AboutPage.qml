import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

Page {
   header: HangupsHeader {
       title: i18n.tr("About")
       flickable: flickable
   }
   visible: false

   Flickable {
       id: flickable
       clip: true
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
                width: parent.width
                horizontalAlignment: Text.Center
                text: "Ubuntu Hangups"
                fontSize: "x-large"
           }

           RowLayout {
               width: parent.width
               UbuntuShape {
                   Layout.alignment: Qt.AlignHCenter
                   width: units.dp(64)
                   height: units.dp(64)
                   source: Image {
                       source: "../ubuntu-hangups.png"
                   }
               }
           }

           Label {
               width: parent.width
               horizontalAlignment: Text.Center
               visible: false
               text: i18n.tr("Version %1")
               Component.onCompleted: {
                    py.importModule("backend", function(){
                        text = text.arg(py.evaluate("backend.__version__"));
                        visible = true;
                    })
                }
           }

           FlexibleLabel {
               width: parent.width
               horizontalAlignment: Text.Center
               text: i18n.tr("Inofficial Google Hangouts client for Ubuntu Touch")
           }

           Item { height: units.gu(2); width: parent.width }    // Spacer

           FlexibleLabel {
               text: i18n.tr("Source code available on <a href='%1'>GitHub</a>").arg("https://github.com/tim-sueberkrueb/ubuntu-hangups")
                             + "<br/><br/>This application is free software: you can redistribute it and/or modify it under the terms of"
                             + " the GNU General Public License as published by the Free Software Foundation, either version 3 of the "
                             + "License, or (at your option) any later version.<br/><br/> (C) Copyright 2015-2016 by Tim Süberkrüb<br/>"
               onLinkActivated: Qt.openUrlExternally(link)
           }           

           FlexibleLabel {
               text: i18n.tr("Third-party Software")
               font.pixelSize: units.dp(24)
           }

           FlexibleLabel {
                text: i18n.tr("The application icon was created by <a href='%1'>Sam Hewitt</a>".arg("http://samuelhewitt.com/"))
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
                text: i18n.tr("This application uses <a href='%1'>Tom Dryer</a>'s inofficial Google Hangouts Python library "+
                              "<a href='%2'>Hangups</a>."+
                              " Hangups is released under the MIT license.").arg("https://github.com/tdryer").arg("https://github.com/tdryer/hangups")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
                text: i18n.tr("Powered by <a href='%1'>Thomas Perl's</a> <a href='%2'>PyOtherSide</a>").arg("https://github.com/thp").arg("https://github.com/thp/pyotherside")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
               text: i18n.tr("The loading animation was created by %1.").arg("Fabian Süberkrüb")
           }

           FlexibleLabel {
                text: i18n.tr("The <a href='%1'>default chat background</a> was created by <a href='%2'>Patrick Hoesly</a> and is licensed "+
                              "under the <a href='%3'>Creative Commons Attribution 2.0 Generic (CC BY 2.0) license.</a>")
                               .arg("https://www.flickr.com/photos/zooboing/5127310748/")
                               .arg("https://www.flickr.com/photos/zooboing/")
                               .arg("https://creativecommons.org/licenses/by/2.0/")
                onLinkActivated: Qt.openUrlExternally(link)
           }

           FlexibleLabel {
               text: i18n.tr("This application is not endorsed by or affiliated with Ubuntu or Canonical. Ubuntu and Canonical are registered trademarks of Canonical Ltd.")
           }
       }
   }
}
