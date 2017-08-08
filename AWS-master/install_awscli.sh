#!/bin/bash

curl -s https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh >/tmp/common-functions.sh
source /tmp/common-functions.sh

CheckRoot
CheckSELinux

which pip &>/dev/null
if [ $? -ne 0 ]; then 
	error "Python Installer not Installed"
fi

yum install python2-pip -y &>/dev/null
which pip &>/dev/null
if [ $? -ne 0 ]; then
    error "Unable to install Python Installer."
	info " Checking alternate ways"
	EnableEPEL
	yum install python2-pip -y &>/dev/null
	which pip &>/dev/null
	if [ $? -ne 0 ]; then
        error "Still Unable to install Python Installer."
		info "Try to install manually"
		exit 1
	fi
else
	success "Installed Python Installer Successfully"
fi

pip install awscli csvkit &>/dev/null
if [ $? -eq 0 ]; then 
	success "Install AWSCLI Successfully"
else
	error "AWSCLI Installation Failed.. Try manually"
	exit 1
fi




