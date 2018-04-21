#!/bin/bash

sudo apt-get install python-glade2 python-appindicator python-pexpect python-gconf
cd ~/Downloads
git clone https://github.com/Kilian/f.lux-indicator-applet.git
cd f.lux-indicator-applet
chmod +x setup.py
sudo ./setup.py install
sudo chmod +x /usr/local/bin/xflux
fluxgui
