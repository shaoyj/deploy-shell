#!/bin/bash -
#Program:
#               导航菜单
#History
#       2016/02/24 


#!/bin/bash -
#Program:
#               function shell ( Scalable, interactive deployment script. )
#History
#       2016/02/24

source /etc/profile
export PATH=$(echo $PATH)
export PROJECT_HOME=$(cd $(dirname $0)/..; pwd)


#tomcat 部署目录
export TOMCAT_ARRAY=($(ls ${HOME} |  egrep -v 'data|logs'))

#red
export RED='\e[1;31m'
#blue
export blue='\e[0;34m'
#colorless
export NC='\e[0m'


#Traverse the array and print
printTomcatList()
{
	i=0
	while [ $i -lt ${#TOMCAT_ARRAY[@]} ]
	do
		echo "					$(($i+1)).${TOMCAT_ARRAY[$i]}	"
		let i++
	done
}

#Validate
validInput()
{
	read -p  "please enter  option : " option

	until [ "$option" -ge $1 -a "$option" -le $2 ] 2>/dev/null
	do
	read -p "option should be a number  between $1 and $2 .Please re-enter option : " option
	done
	echo ${option}
}

#resulr Function
resultInfo()
{
	if [ $1 -eq 0 ]  2>/dev/null;then
			echo -e "${blue}$2 [ok]  ${NC}"
			return 0
	else
			echo -e "${RED}$2 [failed] ${NC}"
			return 1
	fi
}

mainMenuArray=("check  tomcat" "stop  tomcat")
#man menu
mainMenu()
{
	echo "######################################## tomcat_manager_shell menu ########################################"
	i=0
	while [ $i -lt ${#mainMenuArray[@]} ]
	do
		echo "					$(($i + 1)).${mainMenuArray[$(($i))]} "
		let i++
	done
	echo "					0.exit	        "
	#validate option
	res=$(validInput 0 ${#mainMenuArray[@]})
	#next menu
	case $res in
		0) exit 0;;
		*) secondMenu $res;;
	esac
}

#second Menu
secondMenu()
{
	echo "######################################## ${mainMenuArray[$(($1 - 1))]} menu ########################################"
	printTomcatList
	echo "					0.back	"
        echo "                                       -1.ALL   "

	#validate option
	res=$(validInput -1 ${#TOMCAT_ARRAY[@]})
	#execute
	if [ $res -eq 0 ];then
		mainMenu
		exit 0;
	fi

	if [ $res -eq -1 ];then
		for tomName in ${TOMCAT_ARRAY[@]};
		do
			case $1 in
				1) checkTomcat ${tomName} ;;
				2) stop ${tomName} ;;
				*) echo "next menu appear a exception";;
			esac
		done
	else
		case $1 in
			1)  checkTomcat ${TOMCAT_ARRAY[$(($res - 1))]} ;;
			2)  stop ${TOMCAT_ARRAY[$(($res - 1))]} ;;
			*) echo "next menu appear a exception";;
		esac
	fi

	#Back to the main menu
	mainMenu
}

#check tomcat
getServerPid()
{
   local tomName=$1
   local tempPid=$(ps x|grep ${tomName}| grep -v grep |grep -v $0| grep -v -E 'data|logs' |sed -n '1p' |awk '{print $1}'|xargs echo );
   echo ${tempPid}
}

#kill tomcat 1: tomcatName
stop()
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

#check tomcat
checkTomcat()
{
    local tomName=$1
    local pid=$(getServerPid ${tomName})

    if [[ ! -n ${pid} ]];then
        echo -e "${RED}'${tomName}' Not Running. ${NC}"
    else
        echo -e "${blue}'${tomName}' is Running. ${NC}"
    fi
}


#Load the main menu
mainMenu




