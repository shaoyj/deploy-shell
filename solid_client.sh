#!/bin/bash
#Program:
#            solid_client shell
#descritopn
#           Client server deployment script ( Current user directory )
#Required
#           The system needs to install wget, curl, java command
#History
#       2018/01/22

# Introduce system variables (get java command)
source /etc/profile

#Project Deployment Directory
export SERVER_HOME=${HOME}

#Configure the server address
export CONF_DOMAIN=http://deploy.solidtracking.com

#jar package store address
export JAR_ADDRESS=http://deploy.solidtracking.com


#red
export RED='\e[1;31m'
#blue
export blue='\e[0;34m'
#colorless
export NC='\e[0m'


# Verify file exists
is_exist_file()
{
    if [[ ! -f $1 ]];then
	        echo -e "${RED}'$1' does not exist ${NC}" >&2
	        exit 1
	fi
}


#resulr Function
resultInfo()
{
	if [[ 0 -eq $1 ]] ;then
		echo -e "${blue}$2 [ok] ${NC}"
	else
		echo -e "${RED}$2 [failed] ${NC}" >&2
		exit 1
	fi
}

#Initialization (whether the project is verified by the server)
init()
{
    #Verify whether it is a ROOT user
    if [[ "ROOT" == "$(echo $(whoami))" ]] ;then
        echo -e "${RED}ROOT users are prohibited from executing commands. ${NC}" >&2
        exit 1
    fi

    #Get tomcat Name
    local tomName=$1

    #Whether to force an update
    local FORCE=$2

    #Whether to update the deployment script
    if [[ ! -x ${HOME}/.deploy/bin/solid_client.sh || "-force" == "${FORCE}" ]]; then
        #If the deployment directory does not exist then create
        [[ ! -d ${HOME}/.deploy/bin/ ]] && mkdir -p ${HOME}/.deploy/bin/
        #If the deployment script does not exist then download (wget uri -O file way to overwrite the file, do not need to delete the file in advance)
        wget ${CONF_DOMAIN}/deploy/solid_client.sh  -O ${HOME}/.deploy/bin/solid_client.sh
        chmod 751 ${HOME}/.deploy/bin/solid_client.sh;
        #info
        if [[ $? -eq 0 ]] ;then
            echo -e "${blue} ${ip_address} Initialization result is [ok] ${NC}"
        else
            echo -e "${RED} ${ip_address} Initialization result is [failed] ${NC}" >&2
        fi
    fi

    #Import to the user's environment variables
    [[ ! -f ${HOME}/.bashrc ]] && touch ${HOME}/.bashrc
    if [[ $(cat ${HOME}/.bashrc |grep "/.deploy/bin" |wc -l) -eq 0 ]]; then
        echo 'export PATH=${HOME}/.deploy/bin:$PATH'>>${HOME}/.bashrc
        source ${HOME}/.bashrc
     fi

    #Native IP
    if [[ ! -f ${HOME}/.ip || "-force" == "${FORCE}" ]]; then
        wget ${CONF_DOMAIN}/deploy/ip -O ${HOME}/.ip
	fi

    # Initialize the directory
    #Project directory
    if [[ ! -d ${SERVER_HOME}/${tomName}/ ]]; then
	  mkdir -p ${SERVER_HOME}/${tomName}/
	fi

    #config  bin
    if [[ ! -d ${SERVER_HOME}/${tomName}/bin/ || "-force" == "${FORCE}" ]]; then
         #If the deployment directory does not exist then create
        [[ ! -d ${SERVER_HOME}/${tomName}/bin/ ]] && mkdir -p ${SERVER_HOME}/${tomName}/bin/
        #Verify script exists
        if [[ $(curl -s -I ${CONF_DOMAIN}/deploy/shell/${tomName}/${tomName}.sh |grep 200 |wc -l) -ne 0 ]]; then
          wget ${CONF_DOMAIN}/deploy/shell/${tomName}/${tomName}.sh -O ${SERVER_HOME}/${tomName}/bin/${tomName}.sh
          chmod 700 ${SERVER_HOME}/${tomName}/bin/${tomName}.sh
        fi
	fi

    #config  directory
    # Download 'spring boot admin' configuration, external exposure interface
    if [[ ! -d ${SERVER_HOME}/${tomName}/config/ ]]; then
	  mkdir -p ${SERVER_HOME}/${tomName}/config/
	fi
    #Overlay configuration
    if [[ ! -f ${SERVER_HOME}/${tomName}/config/application.properties || "-force" == "${FORCE}" ]]; then
        local spring_boot_admin_result=$(curl -s ${CONF_DOMAIN}/deploy/admin?serverName=${tomName})
        if [[ "" != "${spring_boot_admin_result}" ]]; then
            echo -e ${spring_boot_admin_result} >${SERVER_HOME}/${tomName}/config/application.properties
        fi
	fi

	#Download 'JVM' configuration
    if [[ ! -f ${SERVER_HOME}/${tomName}/config/jvm || "-force" == "${FORCE}" ]]; then
        local jvm_params=$(curl -s ${CONF_DOMAIN}/deploy/jvm_params?serverName=${tomName})
        if [[ "" != "${jvm_params}" ]]; then
            echo ${jvm_params} >${SERVER_HOME}/${tomName}/config/jvm
        fi
	fi

    resultInfo $? "${tomName} init result :";
}

#Install
install()
{
    local tomName=$1
	#校验目录是否存在
    if [[ -d ${SERVER_HOME}/${tomName}/ ]]; then
	    echo -e "${RED}${tomName} already exists ${NC}" >&2
	    exit 1
	else
	   #Check whether the project exists or not
	   if [[ ! -n $(curl -s ${CONF_DOMAIN}/deploy/exist?serverName=${tomName}) ]]; then
	        echo -e "${RED}${tomName} is not configured on the deployment server. ${NC}" >&2
            exit 1
	   else
	        #Get the real name of the project
	        local RES_TOM_NAME=$(echo ${tomName} |awk -F '_' '{print $1}')
	        init ${RES_TOM_NAME} >/dev/null
	   fi

	   #pull
	   pullRoot ${tomName} >/dev/null

	   #result
	   resultInfo $? "${tomName} install result :";
	fi
}

# 1: tomcatName
pullRoot()
{
    local tomName=$1
    #Get the real name of the project
	local RES_TOM_NAME=$(echo ${tomName} |awk -F '_' '{print $1}')
    #Cover jar package
    wget ${JAR_ADDRESS}/deploy/jar/${RES_TOM_NAME}/${RES_TOM_NAME}.jar -O ${SERVER_HOME}/${tomName}/${tomName}.jar

    resultInfo $? "${tomName} pull result :";
}

#kill tomcat 1: tomcatName
killTomcat()
{
    local tomName=$1
    local pid=$(getServerPid ${tomName})
    if [[ ! -n ${pid} ]];then
        echo -e "${RED}'${tomName}' Not Running. ${NC}" >&2
        exit 1
    fi
    kill -9 ${pid}
	resultInfo $? "${tomName} stop result :";
}

#startTomcat 1: tomcatName
startTomcat()
{
    local tomName=$1
	#Get pid
    local pid=$(getServerPid ${tomName})
    #Verify that the service is running
    if [[ ${pid} -gt 1 ]];then
        echo -e "${RED} '${tomName}' is Running,now ${NC}" >&2
        exit 1
    else
         is_exist_file ${SERVER_HOME}/${tomName}/${tomName}.jar
         [[ ! -d ${SERVER_HOME}/${tomName}/logs/ ]] && mkdir -p ${SERVER_HOME}/${tomName}/logs/
         #Enter the directory and start the service.
         cd ${SERVER_HOME}/${tomName}
         #Get JVM params
         local jvm_params="-server"
         if [[ -f ${SERVER_HOME}/${tomName}/config/jvm ]]; then
            jvm_params=$(cat ${SERVER_HOME}/${tomName}/config/jvm)
         fi
         #启动
         nohup java ${jvm_params} -jar ./${tomName}.jar >./logs/${tomName}_catalina.log 2>&1 &
    fi

	resultInfo $? "${tomName} start result :";
}

#restart 1: tomcatName
restart()
{
    local tomName=$1
    local pid=$(getServerPid ${tomName})
    if [[ -n ${pid} ]];then
        killTomcat ${tomName}>/dev/null
     else
        echo -e "${RED}${tomName} No Running. ${NC}" >&2
    fi
	startTomcat ${tomName} >/dev/null

	resultInfo $? "${tomName} restart result :";
}

#check tomcat
getServerPid()
{
   local tomName=$1
   local tempPid=$(ps x|grep ${tomName}.jar| grep -v grep |grep -v $0 |sed -n '1p' |awk '{print $1}'|xargs echo );
   echo ${tempPid}
}

#Display tomcat current status
status()
{
    local tomName=$1
    local pid=$(getServerPid ${tomName})
    if [[ ${pid} -gt 1 ]];then
        echo -e "${blue}'${tomName}' is Running,now ${NC}"
    else
        echo -e "${blue}'${tomName}' Not Running ${NC}"
    fi
}

#backUpTomcat
backUpTomcat()
{
    local tomName=$1
    is_exist_file ${SERVER_HOME}/${tomName}/${tomName}.jar
    #Create a backup directory does not exist
	if [ ! -d ${SERVER_HOME}/${tomName}/history/backup/ ]; then
	  mkdir -p ${SERVER_HOME}/${tomName}/history/backup/
	fi
	#Backup
	if [[ -f ${SERVER_HOME}/${tomName}/${tomName}.jar ]]; then
	    cp ${SERVER_HOME}/${tomName}/${tomName}.jar ${SERVER_HOME}/${tomName}/history/backup/
        cd ${SERVER_HOME}/${tomName}/history/backup/
        tar -zcf ${tomName}.`date '+%Y%m%d_%H%M%S'`.tar.gz ./${tomName}.jar
        rm ./${tomName}.jar
        #Keep seven versions
        ls -t  ${SERVER_HOME}/${tomName}/history/backup/ |tail -n +7 |xargs rm -rf
        resultInfo $? "${tomName} backUp result :";
    else
        echo -e "${blue}'${SERVER_HOME}/${tomName}/${tomName}.jar' skip backup ${NC}"
	fi
}

#update
update()
{
    local tomName=$1
    #Whether to force an update
    local FORCE=$2
    if [[ "-force" == "${FORCE}" ]] ;then
        #Get the real name of the project
	    local RES_TOM_NAME=$(echo ${tomName} |awk -F '_' '{print $1}')
        init ${RES_TOM_NAME} "-force"
    fi
	#kill ( For a little longer interval )
	local pid=$(getServerPid ${tomName})
    if [[ -n ${pid} ]];then
        killTomcat ${tomName} >/dev/null
    fi
	#backup
	backUpTomcat ${tomName} >/dev/null
	#pull
	pullRoot ${tomName} >/dev/null
	#start
	startTomcat ${tomName} >/dev/null
	resultInfo $? "${tomName} update result :";
}

#Uninstall
uninstall()
{
    local tomName=$1
    #kill ( For a little longer interval )
	local pid=$(getServerPid ${tomName})
    if [[ -n ${pid} ]];then
        killTomcat ${tomName} >/dev/null
    fi
    #移除
    if [ -d ${SERVER_HOME}/${tomName} ]; then
	    rm -rf ${SERVER_HOME}/${tomName}
	    resultInfo $? "${tomName} uninstall result :";
	else
	    echo -e "${RED}${tomName}does not exist. ${NC}"
	fi
}


#main
if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo -e "${RED}you should do like this : $0 serverName -[install|status|start|stop|restart|update|uninstall] [-force] ${NC}" >&2
    exit 1
else
    #Get tomcat service name
    tomName=$1

    #Choose a command
    case $2 in
			-install)   install ${tomName} ;;
			-status)    status ${tomName} ;;
			-start)     startTomcat ${tomName} ;;
			-stop)      killTomcat ${tomName} ;;
			-restart)   restart ${tomName};;
			-update)    update ${tomName} $3;;
			-uninstall) uninstall ${tomName};;
			*) echo -e "${RED}you should do like this : $0 serverName -[install|status|start|stop|restart|update|uninstall] [-force] ${NC}" >&2; exit 1;
    esac
    exit $?
fi
