#!/bin/bash
declare -r LOG='/var/log/nginx/access.log'
declare -r INT='^[0-9]+$'

function Error() {
	case $1 in
		1) echo "Unknown error";;
	esac
	exit 1
}
function Bytes2Mb() { mega=`echo "scale=2;$1/1000000" | bc`; } # Converts bytes to megabytes
function GetIP() { ip=`echo "$1" | cut -d' ' -f1`; } # Get IP address
function GetBandwd() { bandwd=`echo "$1" | cut -d' ' -f10`; } # Get bandwidth (bytes)
function HexResolver() { hexComp=`echo "$1" | sed 's|%|\\\x|g'`; string=`echo -e "$hexComp"`; } # Converte hex to text
function IPBandwidth() {
	totalBandwd=0; allIP=""; list=""
	echo -e "Addresses\tMegabytes"
	echo '-------------------------------'
	while read -r line; do
		line=`echo "$line" | tr -s ' '`
		GetIP "$line"
		allIP+="$ip\n"
	done < $LOG
	uniqueIP=`echo -e "$allIP" | sort -u`
	IFS=$'\n' inarr=(${uniqueIP});
	for ((i=0; i<${#inarr[@]}; i++)); do
		lines=`grep ${inarr[i]} $LOG`
		IFS=$'\n' line=(${lines});
		ipBandwd=0
		for ((j=0; j<${#line[@]}; j++)); do
			GetBandwd "${line[j]}"
			if [[ $bandwd =~ $INT ]]; then ipBandwd=$(($bandwd+$ipBandwd)); fi # If bandwidth is int. Prevents fail from credential with space.
		done
		Bytes2Mb $ipBandwd
		totalBandwd=$(($ipBandwd+$totalBandwd))
		list+="${inarr[i]};$mega\n" # Format: ip;bandwidth
	done
	Bytes2Mb $totalBandwd
	echo -e "$list" | tr ';' $'\t'
	echo "Total: $mega Mb"
}
case "$1" in
	"--bandwidth") IPBandwidth; Error 0;;
	"--info") Infos;;
esac # To bypass menu
