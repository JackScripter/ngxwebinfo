#!/bin/bash
# Multiple access file, useful if you have multiple site writting log to different file.
declare -r LOG=(
        '/var/log/nginx/site1_access.log' 'Site1'
        '/var/log/nginx/private_access.log' 'Private'
        '/var/log/nginx/access.log' 'General'
)
declare -r INT='^[0-9]+$'

function Error() {
        case $1 in
                1) echo "aa";;
        esac
        exit 1
}
function Bytes2Mb() { mega=`echo "scale=2;$1/1000000" | bc`; } # Converts bytes to megabytes
function GetIP() { ip=`echo "$1" | cut -d' ' -f1`; } # Get IP address
function GetBandwd() { bandwd=`echo "$1" | cut -d' ' -f10`; } # Get bandwidth (bytes)
function HexResolver() { hexComp=`echo "$1" | sed 's|%|\\\x|g'`; string=`echo -e "$hexComp"`; } # Converte hex to text
function GetInfo() {
        user=`echo "$1" | cut -d' ' -f3`
        accessTime=`echo "$1" | cut -d'[' -f2 | cut -d' ' -f1`
        req=`echo "$1" | cut -d'"' -f2`
}
function IPBandwidth() {
        totalBandwd=0
        for ((h=0; h<${#LOG[@]}; h++)); do      # Loop through LOG array.
                if [ $(( $h % 2 )) == 0 ]; then # If pair then is path to log file.
                        siteBandwd=0; allIP=""; list=""
                        nameSite=$((h + 1))     # Retrieve site name from array.
                        echo "Site: ${LOG[nameSite]}"
                        echo -e "Addresses\tMegabytes"
                        echo '-------------------------------'
                        while read -r line; do
                                line=`echo "$line" | tr -s ' '`
                                GetIP "$line"
                                allIP+="$ip\n"
                        done < ${LOG[h]}
                        uniqueIP=`echo -e "$allIP" | sort -u`
                        IFS=$'\n' inarr=(${uniqueIP});
                        for ((i=0; i<${#inarr[@]}; i++)); do
                                lines=`grep ${inarr[i]} ${LOG[h]}`
                                IFS=$'\n' line=(${lines});
                                ipBandwd=0      # Reset bandwidth for single IP.
                                for ((j=0; j<${#line[@]}; j++)); do
                                        GetBandwd "${line[j]}"
                                        if [[ $bandwd =~ $INT ]]; then ipBandwd=$(($bandwd+$ipBandwd)); fi # If bandwidth is int. Prevents fail from credential with space.
                                done
                                Bytes2Mb $ipBandwd      # Bandwidth for single IP
                                siteBandwd=$(($ipBandwd+$siteBandwd))   # Addition site total bandwidth
                                list+="${inarr[i]};$mega\n" # Format: ip;bandwidth
                        done
                        Bytes2Mb $siteBandwd
                        totalBandwd=$(($totalBandwd+$siteBandwd))
                        echo -e "$list" | tr ';' $'\t'
                        echo -e "Site usage: $mega Mb\n"
                fi
        done
        Bytes2Mb $totalBandwd
        echo "Total usage: $mega Mb"
}
function Infos() {
        for ((h=0; h<${#LOG[@]}; h++)); do      # Loop through LOG array.
                if [ $(( $h % 2 )) == 0 ]; then # If pair then is path to log file.
                        nameSite=$((h + 1))
                        echo "Site: ${LOG[nameSite]}"
                        echo -e "IP\t\tUSER\tTIME\t\t\tBANDWIDTH\tREQUEST"
                        while read -r line; do
                                line=`echo "$line" | tr -s ' '`
                                GetInfo "$line"
                                GetIP "$line"
                                GetBandwd "$line"
                                HexResolver "$req"
                                Bytes2Mb $bandwd
                                echo -e "$ip\t$user\t$accessTime\t$mega\t$string"
                        done < ${LOG[h]}
                fi
        done
}
case "$1" in
        "--bandwidth") IPBandwidth; Error 0;;
        "--info") Infos;;
esac # To bypass menu
function Main() {
        echo '========================================='
        echo -e "= 1 - Get infos\t\t\t\t="
        echo -e "= 2 - Get bandwidth per IP\t\t="
        echo '========================================='
        read -p "Choose: " answer
        case "$answer" in
                1) Infos;;
                2) IPBandwidth;;
                *) Error 0;;
        esac
        Main
}
Main
