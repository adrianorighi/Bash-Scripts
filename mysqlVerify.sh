#!/bin/bash

####################################
# Shell Script by adrianorighi.com #
#     contato@adrianorighi.com     #
#        adrianorighi.com          #
####################################

if [[ ! "$(service mysql status)" =~ "start/running" ]]
then
    service mysql start
fi

