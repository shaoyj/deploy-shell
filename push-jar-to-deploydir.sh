#!/bin/bash
#Program:
#           push-jar-to-nginx shell
#descritopn
#           Save the jar from the jenkins directory to the deployment directory script
#
#History
#       2018/02/05

export PROJECT_HOME=$(cd $(dirname $0)/..; pwd)
source ${PROJECT_HOME}/config/push_jar_to_deploydir.conf  2>/dev/null

#red
export RED='\e[1;31m'
#blue
export blue='\e[0;34m'
#colorless
export NC='\e[0m'

#resulr Function
resFun()
{
	if [ $1 -eq 0 ]  2>/dev/null;then
			echo -e "${blue}$2 [ok] ${NC}"
			return 0
	else
			echo -e "${RED}$2 [failed] ${NC}"
			return 1
	fi
}

# Verify file exists
is_exist_file()
{
    if [[ ! -f $1 ]];then
	        echo -e "${RED}'$1' does not exist ${NC}"
	        exit 1
	fi
}

##deployTomcat by jenkins ( Based on gradle, jenkins, nginx implementation )
mv_jar_from_jenkins_gradle_to_nginx()
{
    local jenkinsProDir=$1;
    local tomName=$2;
    #Project directory does not exist then create
    [[ ! -d ${JAR_DIR_WAIT_PUSH}/${tomName} ]] && mkdir -p ${JAR_DIR_WAIT_PUSH}/${tomName}
	#cover
	if [[ ${jenkinsProDir} == 0 ]]; then
	    #Verify source file exists
	    is_exist_file ${JENKINS_ROOT_DIR}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar
	    cp  ${JENKINS_ROOT_DIR}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    else
        #Verify source file exists
	    is_exist_file ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar
        cp  ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    fi
	#Modify permissions
	chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${JAR_DIR_WAIT_PUSH}/${tomName}
	resFun $? "$tomName mv_jar_from_jenkins_gradle_to_nginx result : ";
}

#deployTomcat by jenkins ( Based on maven, jenkins, nginx implementation )
mv_jar_from_jenkins_maven_to_nginx_dir()
{
    local jenkinsProDir=$1;
    local tomName=$2;
    #Project directory does not exist then create
    [[ ! -d ${JAR_DIR_WAIT_PUSH}/${tomName} ]] && mkdir -p ${JAR_DIR_WAIT_PUSH}/${tomName}
	#cover
	if [[ ${jenkinsProDir} == 0 ]]; then
	    #Verify source file exists
	    is_exist_file ${JENKINS_ROOT_DIR}/${tomName}/target/${tomName}-${JAR_VERSION}.jar
	    cp  ${JENKINS_ROOT_DIR}/${tomName}/target/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    else
        #Verify source file exists
	    is_exist_file ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/target/${tomName}-${JAR_VERSION}.jar
        cp  ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/target/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    fi
	#Modify permissions
	chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${JAR_DIR_WAIT_PUSH}/${tomName}
	resFun $? "$tomName mv_jar_from_jenkins_maven_to_nginx_dir result : ";
}

if [[ ! -n "$1" || ! $# -eq 3 ]]; then
    echo -e "${RED}you should do like this : $0 -[maven|gradle] jenkinsProDir tomName ${NC}"
    exit 1
else
    #Choose a command
    case $1 in
			-maven)      mv_jar_from_jenkins_maven_to_nginx_dir $2 $3 ;;
			-gradle)     mv_jar_from_jenkins_gradle_to_nginx $2 $3 ;;
			*) echo -e "${RED}you should do like this : $0 -[maven|gradle] jenkinsProDir tomName ${NC}" >&2; exit 1;
    esac
    exit $?
    mv_jar_from_jenkins_maven_to_nginx_dir $1 $2 $3
fi