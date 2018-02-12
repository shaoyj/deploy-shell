#!/bin/bash -
#Program:
#          solid_server shell
#descritopn
#          Remote deployment script
#
#History
#       2018/02/03
#author
#       ShaoYongJun

#Set the configuration server address
export CONF_DOMAIN=

#red
export RED='\e[1;31m'
#blue
export blue='\e[0;34m'
#colorless
export NC='\e[0m'

#Verify the IP address
check_ip()
{
    local IP_ADDRESS=$1
    local regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\b"
    local ckStep2=$(echo ${IP_ADDRESS} | egrep $regex | wc -l)
    if [[ $ckStep2 -eq 0 ]]
    then
           echo -e "${RED}The string ${IP_ADDRESS} is not a correct ipaddr!!! ${NC}"
           exit 1
    else
           echo ${IP_ADDRESS}
    fi
}


#Log in remotely according to IP and execute the command
remote_command()
{
#IP
local ip_address=$(check_ip $1);
#service name
local SERVER_NAME=$2
#command name
local COMMAND=$3
#Whether to force an update
local FORCE=$4

#Log in to the trusted machine
ssh ${ip_address} <<SYJ
if [[ ! -x ${HOME}/.deploy/bin/solid_client.sh ]]; then
    #If the deployment directory does not exist then create
    [[ ! -d ${HOME}/.deploy/bin/ ]] && mkdir -p ${HOME}/.deploy/bin/
    #download
    wget ${CONF_DOMAIN}/deploy/solid_client.sh  -O ${HOME}/.deploy/bin/solid_client.sh
    chmod 751 ${HOME}/.deploy/bin/solid_client.sh;
    #info
    if [[ $? -eq 0 ]] ;then
		echo -e "${blue}${ip_address} Initialization result is [ok] ${NC}"
	else
		echo -e "${RED}${ip_address} Initialization result is [failed] ${NC}"
	fi
fi
#Execute the script command
${HOME}/.deploy/bin/solid_client.sh ${SERVER_NAME} ${COMMAND} ${FORCE}
exit
SYJ
}

#Verify whether it is a ROOT user
if [[ "ROOT" == "$(echo $(whoami))" ]] ;then
    echo -e "${RED}ROOT users are prohibited from executing commands. ${NC}"
    exit 1
else
    #Check the parameters
    if [[ $# -lt 3 || $# -gt 4 ]]; then
        echo -e "${RED}you should do like this : $0 SERVER_IP SERVER_NAME -[init|status|start|stop|restart|update|uninstall] [-force] ${NC}"
        exit 1
    else
        remote_command $1 $2 $3 $4
    fi
fi