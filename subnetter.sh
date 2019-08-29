#!/bin/bash
SUBNET=$1
NUM=$2
string=$1
usage() {
    echo "Usage:"
    echo "      ./subnetter.sh ip/mask num"
    echo "     ex:  ./subnetter.sh 192.168.0.0/24 3"
    exit 6
}
if [ -z $SUBNET ]; then
    usage
fi
if [ -z $NUM ]; then
    usage
fi
IFS='/' read -r ip mask <<<"$string"

IFS='.' read -r ip1 ip2 ip3 ip4<<< "$ip"
count=0
hosts=0
iplast=$ip4

if [ $mask -gt 31 ]; then
    usage
fi
if [ $mask -lt 1 ]; then
    usage
fi

ip2bin(){
    D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
    bn=${D2B[$1]}
    echo $bn
}

bin2num() {
    bin=$1
    echo "ibase=2; $bin" | bc
}
ip2dec() {
    declare -i a b c d;
    IFS=. read a b c d <<<"$1";    
    echo "$(((a<<24)+(b<<16)+(c<<8)+d))"
}
dec2ip() {
    declare -i a=$((~(-1<<8))) b=$1;
    set -- "$((b>>24&a))" "$((b>>16&a))" "$((b>>8&a))" "$((b&a))";
    local IFS=.;
    echo "$*";
}

get_2ts() {
    n=0
    s=$1
    while ((s/2 >0)); do
	n=$((n+1))
	s=$((s/2))
    done
    echo $n
}
get_num() {
    n=$1    
    s=1
    i=1
    while ((n >= s)); do
	s=$((2**i))
	i=$((i+1))
    done
    echo $((s/2))
}

get_ipmask() {
    ip=$1
    mask=$2
    len=${#ip}
    len=$((len-1))
    s=0
    for ((i=0;i<mask;i++)); do
	a=${ip:i:1}
	s=$((s+a*(2**(len-i))))	
    done
    echo $s
}

print_ipinfo() {
    ipdec=$1
    ihosts=$2
    mask=$3
    broadcast=`dec2ip $((ipdec+ihosts-1))`
    gateway=`dec2ip $((ipdec+1))`
    ip=`dec2ip $ipdec`
    rhost=$((ihosts-3))
    echo "subnet=$ip/$mask network=$ip broadcast=$broadcast gateway=$gateway hosts=$rhost"    
}
ipn=`ip2bin $ip1``ip2bin $ip2``ip2bin $ip3``ip2bin $ip4`

ipdec=`get_ipmask $ipn $mask`

#firstipdec=`bin2num $ipn`
firstipdec=`ip2dec $ip`
#echo $firstipdec
hosts=$((2**(32-mask)))

step=`get_num $NUM`

h=$((hosts/step))
remain=$((hosts%NUM))
count=0

t=`get_2ts $step`

rmask=$((mask+t))

sumh=$((firstipdec-ipdec))
ipdec=$firstipdec
while ((count < NUM)); do
    count=$((count+1))    
    if ((sumh+h>=hosts && count<NUM)); then
	rmask=$((rmask+1))
	step=$((step/2))	
	h=$((h/2))    	
    fi 
    if ((sumh+h>hosts)); then
	break
    fi
    print_ipinfo $ipdec $h $rmask
    sumh=$((sumh+h))
    ipdec=$((ipdec+h))	
done
