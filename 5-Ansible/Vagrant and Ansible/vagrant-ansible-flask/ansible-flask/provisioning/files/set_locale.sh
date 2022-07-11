#!/bin/bash

# Set locales in /etc/default/locale file
echo "Setting locale..."
echo "# Locale settings
export LC_ALL=C
export LANGUAGE=en_US.UTF-8" >> ~/.bashrc


source ~/.bashrc
