#!/bin/bash -
#Program:
#          solid_server shell
#descritopn
#          远程初始化脚本
#
#History
#       2018/02/03
#author
#       ShaoYongJun

#设置配置服务器地址
export CONF_DOMAIN=

#红色
export RED='\e[1;31m'
#蓝色
export blue='\e[0;34m'
#无色
export NC='\e[0m'

#校验 IP 地址
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


#根据IP登录远程,执行命令
remote_command()
{
#IP
local ip_address=$(check_ip $1);
#服务名称
local SERVER_NAME=$2
#command name
local COMMAND=$3
#Whether to force an update
local FORCE=$4

#登录受信机器
ssh ${ip_address} <<SYJ
if [[ ! -x ${HOME}/.deploy/bin/solid_client.sh ]]; then
    #如果部署目录不存在则创建
    [[ ! -d ${HOME}/.deploy/bin/ ]] && mkdir -p ${HOME}/.deploy/bin/
    #下载
    wget ${CONF_DOMAIN}/deploy/solid_client.sh  -O ${HOME}/.deploy/bin/solid_client.sh
    chmod 751 ${HOME}/.deploy/bin/solid_client.sh;
    #info
    if [[ $? -eq 0 ]] ;then
		echo -e "${blue}${ip_address} Initialization result is [ok] ${NC}"
	else
		echo -e "${RED}${ip_address} Initialization result is [failed] ${NC}"
	fi
fi
#执行脚本命令
${HOME}/.deploy/bin/solid_client.sh ${SERVER_NAME} ${COMMAND} ${FORCE}
exit
SYJ
}

#校验是否是ROOT 用户
if [[ "ROOT" == "$(echo $(whoami))" ]] ;then
    echo -e "${RED}ROOT users are prohibited from executing commands. ${NC}"
    exit 1
else
    #校验参数
    if [[ $# -lt 3 || $# -gt 4 ]]; then
        echo -e "${RED}you should do like this : $0 SERVER_IP SERVER_NAME -[init|status|start|stop|restart|update|uninstall] [-force] ${NC}"
        exit 1
    else
        remote_command $1 $2 $3 $4
    fi
fi