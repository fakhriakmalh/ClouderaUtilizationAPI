#!/bin/bash 
function DATE { date +'%Y-%m-%dT%H:%M:%S';}
function datediff {
    d1=$(date -d "$1" +%s) ; d2=$(date -d "$2" +%s)
    echo $(( (d1 - d2) / 86400 ))
}

echo "[ Utilization API ]"
echo "$(DATE)| [INFO] Par#1 & Par#2 must specified with 'YYYY-MM-DDTHH:MM:SS' date format."

# Validating Input Params
if [[ -z $1 ]] || [[ -z $2 ]]; then
	echo "$(DATE)| [WARN] Par#1/Par#2 (From/To) Not Specified! Exitting"
	exit
fi 

#CHANGE THESE ===================================================================================

CLUSTER_NAME=<your cluster name>
CMUSER=<username>:<password> #DRC
URL=http://<ip utility node>:7180/api/v19/timeseries 

#DATE RANGE CONFIG

SYSDATE=$(date +'%Y-%m-%d')
DATENOW=$(date +'%Y-%m-%d' -d "${SYSDATE} 00:00:00")


#OUTPUT FILE JSON

# example of date time format FROM="2021-12-13T12:00:00"; TO="2021-12-13T14:00:00"
FROM=$1 TO=$2

#CHANGE THESE ===================================================================================
#list of query to get custom chart in cloudera manager. Put yours in this array

declare -a QLIST=(
'select%20cpu_user_rate/getHostFact(numCores,1)*100%2Bcpu_system_rate/getHostFact(numCores,1)*100%2Bcpu_nice_rate/getHostFact(numCores,1)*100%2Bcpu_iowait_rate/getHostFact(numCores,1)*100%2Bcpu_irq_rate/getHostFact(numCores,1)*100%2Bcpu_soft_irq_rate/getHostFact(numCores,1)*100%2Bcpu_steal_rate/getHostFact(numCores,1)*100%20where%20category=HOST%20AND%20(hostname%20RLIKE%20"drcbighdp5[1-9].*"%20OR%20hostname%20RLIKE%20"drcbighdp6.*"%20OR%20hostname%20RLIKE%20"drcbighdp7.*")'
'SELECT%20allocated_vcores_cumulative%20where%20category=YARN_POOL%20and%20serviceName="yarn"%20and%20queueName=root'
'select%20cpu_user_rate%20/%20getHostFact(numCores,1)*100%20%2Bcpu_system_rate%20/%20getHostFact(numCores,1)*100%20where%20roleType=impalad'
'select%20mem_rss%20where%20roleType=impalad%20AND%20hostname%20rlike%20"drcbighdp5[1-2].*"'
'select%20mem_rss%20WHERE%20roleType=impalad%20AND%20(hostname%20RLIKE%20"drcbighdp5[3-9].*"%20OR%20hostname%20RLIKE%20"drcbighdp6.*"%20OR%20hostname%20RLIKE%20"drcbighdp7.*")'
'SELECT%20allocated_memory_mb_cumulative%20where%20category=YARN_POOL%20and%20queueName=root'
)

declare -a JSONPARSE=(
'cpuUsage'
'cpuVcore'
'impalaCpuUsage'
'memImpalaCoord'
'memImpalaExec'
'memYARN'
)

echo "$(DATE)| [INIT] Par#1=\"$FROM\" | Par#2=\"$TO\" | Params OK";
i=0

ResultDir="result/$(date +'%Y%m%d')"
mkdir -p $ResultDir
ResultFile="$ResultDir/result_${FROM}_${TO}.txt"
rm $ResultFile
touch $ResultFile


#GetDateFormatted=$(echo $FROM | awk -F'T' '{print$1}')
GetDateFormatted=$(LC_ALL=id_ID.UTF8 date +'%A, %d %B %Y' -d "${FROM}")
GetHourFrom=$(echo $FROM | awk -F'T' '{print$2}' | awk -F':' '{print$1":"$2}')
GetHourTo=$(echo $TO | awk -F'T' '{print$2}' | awk -F':' '{print$1":"$2}')

echo "$(DATE)| [INIT] GetDateFormatted=$GetDateFormatted | GetHourFrom=$GetHourFrom | GetHourTo=$GetHourTo"

GetDOW=('Senin' 'Selasa' 'Rabu' 'Kamis' 'Jumat' 'Sabtu' 'Minggu')

Header="Dear All,

CPU dan memory usage ${GetDateFormatted} pukul $GetHourFrom hingga pukul $GetHourTo terlampir"
Footer="
Best Regards & Stay Healthy,
[Shell Script & Python Script]
"


if [ $( date -d $FROM +%s ) -gt $( date -d $TO +%s ) ]; then
	echo "$(DATE)| [ERR] Par#1/From($FROM) Greater than Par#2/To($TO)"
	exit
fi

echo "$Header" >> $ResultFile
#exit
for QUERY in ${QLIST[@]};do
	#echo "$(DATE)|RUN ${JSONPARSE[$i]} API"
	curl -s -g --user "$CMUSER" "$URL?query=$QUERY%20and%20clusterName=$CLUSTER_NAME&from=$FROM&to=$TO" > jsonresults/${JSONPARSE[$i]}.json
	if [[ $(datediff $(DATE) $1) -gt 0 ]]; then
		GetKey='"max"'
		GetKeyTime='maxTime'
	else
		GetKey='value'
		GetKeyTime='time'
	fi
	if [[ ${JSONPARSE[$i]} == 'memImpalaCoord' ]] || [[ ${JSONPARSE[$i]} == 'memImpalaExec' ]] ; then
		PeakValue0=$(grep $GetKey jsonresults/${JSONPARSE[$i]}.json  | awk -F':' '{print$2}' | sort -n | tail -1 | sed 's/ //g' | sed 's/,//g' )
		ConvertExponentToDecimal=$(echo "$PeakValue0" | awk -F"E" 'BEGIN{OFMT="%10.2f"} {print $1 * (10 ^ $2)}')
		PeakValue=$(echo "scale=2; $ConvertExponentToDecimal / 1024 / 1024 / 1024" | bc)
		PeakTime=$(grep ${PeakValue0} jsonresults/${JSONPARSE[$i]}.json -B 1 | grep ${GetKeyTime} | awk -F'" : "' '{print$2}' | awk -F'.' '{print$1}' | tail -1)
	elif [[ ${JSONPARSE[$i]} == 'memYARN' ]]; then
		PeakValue0=$(grep $GetKey jsonresults/${JSONPARSE[$i]}.json  | awk -F':' '{print$2}' | sort -n | tail -1 | sed 's/ //g' | sed 's/,//g' )
		PeakValue=$(echo "scale=2; $PeakValue0 / 1024 / 1024" | bc)
		PeakTime=$(grep ${PeakValue0} jsonresults/${JSONPARSE[$i]}.json -B 1 | grep ${GetKeyTime} | awk -F'" : "' '{print$2}' | awk -F'.' '{print$1}' | tail -1)
	else 
		PeakValue0=$(grep value jsonresults/${JSONPARSE[$i]}.json  | awk -F':' '{print$2}' | sort -n | tail -1 | sed 's/ //g' | sed 's/,//g' )
		PeakValue=$PeakValue0
		PeakTime=$(grep ${PeakValue0} jsonresults/${JSONPARSE[$i]}.json -B 1 | grep time | awk -F'" : "' '{print$2}' | awk -F'.' '{print$1}' | tail -1)
	fi

	CountLenTitle=$(echo ${JSONPARSE[$i]} |wc -m); if [[ $CountLenTitle -lt 10 ]]; then Tab="\t\t" ;else Tab="\t"; fi; 
	echo -e "$(DATE)| RUN ${JSONPARSE[$i]} API${Tab} | PeakTime+7=$( date +'%Y-%m-%dT%H:%M:%S' -d "${PeakTime}+1 hour" ) PeakValue=$( printf "%.2f\n" $(echo "$PeakValue" | bc -l) )"

	i=$(($i+1))
done
	#ExecPython="$(python2 parse_${JSONPARSE[$i]}.py)"
	ExecPython="$(python2 parse_all.py)"
	echo "$ExecPython" >> $ResultFile
echo "$Footer" >> $ResultFile

echo;echo;echo;echo "#================================================================================"
echo "ResultFile=$ResultFile" ; echo

cat $ResultFile
