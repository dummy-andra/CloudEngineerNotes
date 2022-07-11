#!/bin/bash


echo 'se instaleaza python-dev'
sudo apt install python-dev
echo 'se face cd in home'
cd /home ; echo 'clonam spi'; git clone https://github.com/lthiery/SPI-Py.git ; echo 'cd in spi' ;cd SPI-Py ; echo 'bilduim spi' ; sudo python setup.py build && python setup.py install
echo "Instalare validator si activare serviciu"

sudo dpkg -i /home/validator_1.6.*_armhf.deb

sudo systemctl --system daemon-reload 
sudo systemctl enable validator 
sudo systemctl start validator 
sudo systemctl status validator

echo 'Europe/Bucharest' > /etc/timezone
