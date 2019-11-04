# Init
lesskey=false
tput civis   
current_position=1         
idx=1
end=false
ext=0

red=`echo -e '\033[1;31m'`
green=`echo -e '\033[1;32m'`
yellow=`echo -e '\033[1;33m'`
normal=`echo -e '\033[0m'`
whitebold_re=`echo -e '\033[1m'`
whitebold="\033[1m"
OFF="\033[0m"

# setkeys.
arrowup="`echo -e '\e[A'`" 
arrowdown="`echo -e '\e[B'`" 
arrowright="`echo -e '\e[B'`" 
arrowleft="`echo -e '\e[B'`" 
#escape | echape
ec="`echo -e '\e'`"
#entré
nl="`echo -e '\n'`"
arrowup_1="k"
arrowdown_1="j"
nl_1="e"


tputcolors() {
    normal=$(tput sgr0)
    reverse=$(tput rev)
    BLUE=$(tput setaf 6)
} 

untputcolors() {
    green=""
    yellow=""
    normal=""
    reverse=""
}

cls() {
    echo -e "\E[J"
    tput cuu1
}


if [[ -t 1 ]] && which tput &>/dev/null && tput colors &>/dev/null; then
    ncolors=$(tput colors)
    if [[ -n "$ncolors" ]] && [[ "$ncolors" -ge 8 ]] ; then
	tputcolors
    else
	untputcolors
    fi
else
    untputcolors
fi
docker_lines=$(docker container list -a|wc -l)
docker_listview=$(($docker_lines - 1))

# docker view template.
docker_container_list="docker container list -a \
            --format \"table STATUSCOLOR {{.ID}}OFFCOLOR − {{.Image}}\tBOLDCOLOR({{.RunningFor}})OFFCOLOR\t{{.Status}}\tEXPOSECOLOR{{.Ports}}OFFCOLOR\tBOLDCOLOR<{{.Names}}>OFFCOLOR\" |\
            tail -$docker_listview |\
            sed -e \"s/OFFCOLOR/$normal/g\" \
            -e \"/Exited/s/STATUSCOLOR/$red/\" \
            -e \"/Up/s/STATUSCOLOR/$green/\" \
            -e \"/Created/s/STATUSCOLOR/$yellow/\" \
            -e \"s/EXPOSECOLOR/$BLUE/g\" \
            -e \"s/BOLDCOLOR/$whitebold_re/g\" "



running_container=$(docker container list -a |grep Up|wc -l)
exited_container=$(docker container list -a |grep Exited|wc -l)
created_container=$(docker container list -a |grep Created|wc -l)

IFS=$'\n'
docker=($(eval ${docker_container_list} 2>/dev/null))
unset IFS

NumberC=$(docker container ls -a |wc -l)
container_idx=${#docker[@]}

SN=$(( `tput lines` - 1 ))
CN=$(tput cols)
line_used=$(( $container_idx < $((SN -1)) ? $container_idx : $((SN -1))))
offset=0 

echo -e "containers:${whitebold} $line_used ${OFF}, running:${whitebold} $running_container${OFF}, Exited:${whitebold} $exited_container ${OFF}, created:${whitebold} $created_container ${OFF}\n"
echo -e "$whitebold −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−\n \
container ID − IMAGE              (CREATED)        STATUS                           PORTS                    <NAMES>\n \
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−"

if [[ $docker_listview -eq 0 ]];then
    exit 0;
fi

if command -v lesskey &> /dev/null; then
    lesskey=true
fi
case "$filtred" in
    *)       regex="sed -r s/^\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ;;
esac

for elt in "${docker[@]}"
do
    
    ELT="$(echo "$elt" | $regex)"
    container_uncoll+=("$ELT")
done

for C in "${container_uncoll[@]}"
do
    if [[ ${#C} -gt $CN ]]; then
	offset=$(( offset + 1 ))
    fi
done

if [[ $lesskey = true ]]; then
    echo "\t quit" | lesskey -o /tmp/lsh_less_keys_tmp -- - &> /dev/null
fi
get_containers() {
    ELT="$(echo "${container_uncoll[$current_position-1]}")"
    #extract hash_container started from 8 - 10 characters
    container_HASH=${ELT:8:10}
#    inspect_docker="docker container inspect $container_HASH"
#                    --format \"table IpAdress   : {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\n      \
#                               MacAdress  : {{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}} \n    \
#                               PathLog    : {{.LogPath}}\n                                                  \
#                               ImageName  : {{.Config.Image}} \n                                            \
#                               StartedAt  : {{.State.StartedAt}}\n                                          \
#                               FinishedAt : {{.State.FinishedAt}}\n                                         \
#                               Status     : {{.State.Status}}\" "
    inspect_docker="docker container diff $container_HASH"
    container=$(eval ${inspect_docker} 2>/dev/null)
    tmp_diff="$(echo "$container" | $regex)"
    off=$(echo "$tmp_diff" | grep -c ".\{$CN\}")
    inspect_line_numbers="$(echo "$container" | wc -l)"
    inspect_line_numbers=$(( inspect_line_numbers + off ))
}

set_containers() {
    get_containers
    if [[ $(( line_used + inspect_line_numbers + offset )) -ge $(( `tput lines` - 1 )) ]]; then
	trap - INT
	if [[ $lesskey = true ]]; then
	    echo "$container" | less -r -k /tmp/lsh_less_keys_tmp
	else 
	    echo "$container" | less -r
	fi
	trap cleanup INT
	cls
    else 
	stop=false
	cls
	for i in `seq 1 $line_used`
	do
	    echo -n "$normal"
	    [[ $current_position == "$i" ]] && echo -n "$reverse"
	    echo "${docker[$i - 1]}"
	    [[ $current_position == "$i" ]] && echo "$container"
	done
	while ! $stop
	do
	    read -sn 1 key
	    case "$key" in
		"$nl")
		    stop=true
		    ;;
		"q")
		    stop=true
		    end=true
		    ;;
	    esac
	done
	[[ $end = false ]] && tput cuu $(( line_used + inspect_line_numbers + offset )) && cls
    fi
}

calculate_offset {
    tmp=1
    idx=$(( idx -1 ))
    while [[ $tmp -lt $SN ]]
    do
    	el=${container_uncoll[$idx]}
    	if [[ ${#el} -gt $CN ]] && [[ $current_position -lt $((SN -1)) ]]; then
    	    offset_2=$(( offset_2 + 1 ))
    	    tmp=$(( tmp + 1 ))
    	fi
    	tmp=$(( tmp + 1 ))
    	idx=$(( idx + 1 ))
    done
}
cleanup() {
    [[ $lesskey = true ]] && rm /tmp/lsh_less_keys_tmp

    tput cuu 1
    tput cnorm
    echo "$normal"
    stty "$orig_stty" > /dev/null 2>&1
    exit
}

trap cleanup INT

{


while ! $end
do
    end_idx=0
    if [[  $line_used == $container_idx ]]; then 
	end_idx=$line_used
	offset_2=$offset
    elif [[  $line_used == $(( SN - 1 )) ]]; then
	if [[ $offset != 0 ]]; then 
   	    [[ $current_position -lt $((SN -1)) ]] && offset_2=0
   	    ext=1
   	    calculate_offset
	fi
	end_idx=$(( line_used + idx -1 + ext - offset_2 ))
    fi

    for i in `seq $idx $end_idx`
    do
	echo -n "$normal"
	[[ $current_position == $i ]] && echo -n "$reverse"
	echo "${docker[$i - 1]}"
    done

    read -sn 1 key
    [[ "$key" == "$ec" ]] &&
    {
	read -sn 2 k2
	key="$key$k2"
    }

    case "$key" in
	"$arrowup" | "$arrowup_1")
            current_position=$(( current_position - 1 ))
            [[ $current_position == 0 ]] && [[ $idx == 1 ]] && [[ $line_used == $(( SN - 1 )) ]] && current_position=$container_idx && idx=$(( container_idx - SN + 2 + offset_2 ))
            [[ $current_position == 0 ]] && [[ $idx == 1 ]] && [[ $line_used == $container_idx ]] && current_position=$line_used
            [[ $current_position == $(( idx - 1 )) ]] && [[ $idx != 1 ]] && idx=$(( idx - 1 ))

   	    [[ $line_used != $(( SN - 1 )) ]] && tput cuu $(( line_used + offset_2 ))
   	    [[ $line_used == $(( SN - 1 )) ]] && tput cuu $(( line_used + ext ))
            [[ $idx != 1 ]] && cls
            ;;
	"$arrowdown" | "$arrowdown_1")
   	    current_position=$(( current_position + 1 ))
            [[ $current_position == $(( container_idx + 1 )) ]] && current_position=1 && idx=1 
            [[ $current_position == $(( SN + idx - 1 + ext - offset_2 )) ]] && [[ $line_used == $(( SN - 1 )) ]] && idx=$(( idx + 1 ))

   	    [[ $line_used != $(( SN - 1 )) ]] && tput cuu $(( line_used + offset_2 ))
   	    [[ $line_used == $(( SN - 1 )) ]] && tput cuu $(( line_used + ext ))
            [[ $idx != 1 ]] && cls
            [[ $idx = 1 ]] && [[ $current_position = 1 ]] && cls
            ;;
	"$nl" | "$nl_1")
   	    [[  $line_used == $container_idx ]] && tput cuu $(( line_used + offset_2 ))
   	    [[  $line_used != $container_idx ]] && tput cuu $(( line_used + ext ))
            set_containers 
            ;;
	"q")
            idx=false
            end=true
            ;;
	* )
   	    tput cuu $(( line_used + offset_2 ))
    esac
done

cleanup

} >&2
