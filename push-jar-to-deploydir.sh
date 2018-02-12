#!/bin/bash
#Program:
#           push-jar-to-nginx shell
#descritopn
#           将jar从 jenkins 目录 存入 部署目录 脚本
#
#History
#       2018/02/05

export PROJECT_HOME=$(cd $(dirname $0)/..; pwd)
source ${PROJECT_HOME}/config/push_jar_to_deploydir.conf  2>/dev/null

#红色
export RED='\e[1;31m'
#蓝色
export blue='\e[0;34m'
#无色
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

# 校验文件是否存在
is_exist_file()
{
    if [[ ! -f $1 ]];then
	        echo -e "${RED}'$1' does not exist ${NC}"
	        exit 1
	fi
}

##deployTomcat by jenkins ( 基于gradle、jenkins、nginx 的实现 )
mv_jar_from_jenkins_gradle_to_nginx()
{
    local jenkinsProDir=$1;
    local tomName=$2;
    #项目目录不存在则创建
    [[ ! -d ${JAR_DIR_WAIT_PUSH}/${tomName} ]] && mkdir -p ${JAR_DIR_WAIT_PUSH}/${tomName}
	#覆盖
	if [[ ${jenkinsProDir} == 0 ]]; then
	    #校验源文件是否存在
	    is_exist_file ${JENKINS_ROOT_DIR}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar
	    cp  ${JENKINS_ROOT_DIR}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    else
        #校验源文件是否存在
	    is_exist_file ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar
        cp  ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/build/libs/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    fi
	#修改权限
	chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${JAR_DIR_WAIT_PUSH}/${tomName}
	resFun $? "$tomName mv_jar_from_jenkins_gradle_to_nginx result : ";
}

#deployTomcat by jenkins ( 基于maven、jenkins、nginx 的实现 )
mv_jar_from_jenkins_maven_to_nginx_dir()
{
    local jenkinsProDir=$1;
    local tomName=$2;
    #项目目录不存在则创建
    [[ ! -d ${JAR_DIR_WAIT_PUSH}/${tomName} ]] && mkdir -p ${JAR_DIR_WAIT_PUSH}/${tomName}
	#覆盖
	if [[ ${jenkinsProDir} == 0 ]]; then
	    #校验源文件是否存在
	    is_exist_file ${JENKINS_ROOT_DIR}/${tomName}/target/${tomName}-${JAR_VERSION}.jar
	    cp  ${JENKINS_ROOT_DIR}/${tomName}/target/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    else
        #校验源文件是否存在
	    is_exist_file ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/target/${tomName}-${JAR_VERSION}.jar
        cp  ${JENKINS_ROOT_DIR}/${jenkinsProDir}/${tomName}/target/${tomName}-${JAR_VERSION}.jar ${JAR_DIR_WAIT_PUSH}/${tomName}/${tomName}.jar;
    fi
	#修改权限
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