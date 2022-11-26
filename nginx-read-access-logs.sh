#!/bin/bash
#
# @description  This script allows you to perform a complete analysis of nginx access logs
# @usage        wget -qO .loganalysis.tmp && bash .nginx-logs.tmp
# @author       Giovani Sehnen <giovani.sehnen@confi.gr>
#
# @requires     bash v4+
# @version      0.0.1
#

#
# Global Variables
#
logFile=$1
linesFile=$2

#
# Bootstrap
#
trap cleanup SIGINT SIGTERM EXIT

cleanup(){
  rm -f .nginx-logs.tmp
  exit 1
}

while [ ! -e "${logFile}" ]; do
  read -rp "Informe o log: " -e LOG
done

if [ -z "${linesFile}" ]; then
  LINES=10
fi

is_gzip=$(echo "${logFile}" | grep '.gz')
logFile=$(basename "${logFile}" .gz)

#
# Runtime
#
echo -e "\nAnalisando ${logFile}"

do_gz(){
  log_head=$(zcat "${logFile}" | awk '{print $4, $5}' | head -1)
  log_tail=$(zcat "${logFile}" | awk '{print $4, $5}' | tail -1)
  echo -e "Período: ${log_head} - $log_tail"

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas ==="
  zcat "${logFile}" | awk '{print $7}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas, ignorando query strings ==="
  zcat "${logFile}" | awk '{print $7}' | awk -F'?' '{print $1}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} user-agents que mais acessaram o website ==="
  zcat "${logFile}" | awk -F\" '{print $6}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas com o user-agent ==="
  zcat "${logFile}" | cut -d' ' -f7,12- | tr -d \" | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} referers ==="
  zcat "${logFile}" | awk -F\" '{print $4}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} referers, ignorando query strings ==="
  zcat "${logFile}" | awk -F\" '{print $4}' | awk -F'?' '{print $1}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} response code ==="
  zcat "${logFile}" | awk '{print $9}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} IP addresses ==="
  zcat "${logFile}" | awk '{print $1}' | sort | uniq -dc | sort -nr | head -${linesFile}

}

do_ungz(){
  log_head=$(head -1 "${logFile}" | awk '{print $4, $5}')
  log_tail=$(tail -1 "${logFile}" | awk '{print $4, $5}')
  echo -e "Período: ${log_head} - $log_tail"

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas ==="
  cat "${logFile}" | awk '{print $8}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas, ignorando querystrings ==="
  awk -F\" '{print $2}' "${logFile}" | awk '{print $2}' | awk -F'?' '{print $1}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} user-agents que mais acessaram o website ==="
  awk -F\" '{print $6}' "${logFile}" | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} URLs mais acessadas com o user-agent ==="
  awk -F\" '{print $2 " " $6}' "${logFile}" | cut -d' ' -f2,4- | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} referers ==="
  awk -F\" '{print $4}' "${logFile}" | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} referers, ignorando query strings ==="
  awk -F\" '{print $4}' "${logFile}" | awk -F'?' '{print $1}' | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} response codes mais retornados ==="
  awk '{print $9}' "${logFile}" | sort | uniq -c | sort -nr | head -${linesFile}

  echo -e "\n=== TOP ${linesFile} IP addresses ==="
  awk '{print $1}' "${logFile}" | sort | uniq -dc | sort -nr | head -${linesFile}

}
if [ "${is_gzip}" ]; then

  do_gz

else

  do_ungz

fi
unset LOG log_head log_tail