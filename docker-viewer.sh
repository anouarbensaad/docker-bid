# Init
LESSKEY=false
tput civis   
CURRENT_POS=1         
INDEX=1
END=false
EXT=0

RED=`echo -e '\033[1;31m'`
GREEN=`echo -e '\033[1;32m'`
YELLOW=`echo -e '\033[1;33m'`
NORMAL=`echo -e '\033[0m'`
WHITEBOLD_RE=`echo -e '\033[1m'`
WHITE_BOLD="\033[1m"
OFF="\033[0m"

# setkeys.
ArrowUp="`echo -e '\e[A'`" 
ArrowDown="`echo -e '\e[B'`" 
#escape | echape
ec="`echo -e '\e'`"
#entré
nl="`echo -e '\n'`"
ArrowUp_1="k"
ArrowDown_1="j"
nl_1="e"


function tputcolors() {
    NORMAL=$(tput sgr0)
    REVERSE=$(tput rev)
    BLUE=$(tput setaf 6)
} 

function untputcolors() {
    GREEN=""
    YELLOW=""
    NORMAL=""
    REVERSE=""
}

function cls() {
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
DOCKER_LINES=$(docker container list -a|wc -l)
DOCKER_LIST_VIEW=$(($DOCKER_LINES - 1))

# docker view template.
DOCKER_SET="docker container list -a \
            --format \"table STATUSCOLOR {{.ID}}OFFCOLOR − {{.Image}}\tBOLDCOLOR({{.RunningFor}})OFFCOLOR\t{{.Status}}\tEXPOSECOLOR{{.Ports}}OFFCOLOR\tBOLDCOLOR<{{.Names}}>OFFCOLOR\" |\
            tail -$DOCKER_LIST_VIEW |\
            sed -e \"s/OFFCOLOR/$NORMAL/g\" \
            -e \"/Exited/s/STATUSCOLOR/$RED/\" \
            -e \"/Up/s/STATUSCOLOR/$GREEN/\" \
            -e \"/Created/s/STATUSCOLOR/$YELLOW/\" \
            -e \"s/EXPOSECOLOR/$BLUE/g\" \
            -e \"s/BOLDCOLOR/$WHITEBOLD_RE/g\" "



RUNNING_CONTAINER=$(docker container list -a |grep Up|wc -l)
EXITED_CONTAINER=$(docker container list -a |grep Exited|wc -l)
CREATED_CONTAINER=$(docker container list -a |grep Created|wc -l)

IFS=$'\n'
DOCKER=($(eval ${DOCKER_SET} 2>/dev/null))
unset IFS

NumberC=$(docker container ls -a |wc -l)
CONTAINER_INDEX=${#DOCKER[@]}

SN=$(( `tput lines` - 1 ))
CN=$(tput cols)
LINE_USED=$(( $CONTAINER_INDEX < $((SN -1)) ? $CONTAINER_INDEX : $((SN -1))))
OFFSET=0 

echo -e "containers:${WHITE_BOLD} $LINE_USED ${OFF}, running:${WHITE_BOLD} $RUNNING_CONTAINER${OFF}, exited:${WHITE_BOLD} $EXITED_CONTAINER ${OFF}, created:${WHITE_BOLD} $CREATED_CONTAINER ${OFF}\n"
echo -e "$WHITE_BOLD −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−\n \
CONTAINER ID − IMAGE              (CREATED)        STATUS                           PORTS                    <NAMES>\n \
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−"

if [[ $DOCKER_LIST_VIEW -eq 0 ]];then
    exit 0;
fi

if command -v lesskey &> /dev/null; then
    LESSKEY=true
fi
case "$FILTRED" in
    *)       SED_CMD="sed -r s/^\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ;;
esac

for elt in "${DOCKER[@]}"
do
    
    ELT="$(echo "$elt" | $SED_CMD)"
    CONTAINER_UNCOL+=("$ELT")
done

for C in "${CONTAINER_UNCOL[@]}"
do
    if [[ ${#C} -gt $CN ]]; then
	OFFSET=$(( OFFSET + 1 ))
    fi
done

if [[ $LESSKEY = true ]]; then
    echo "\t quit" | lesskey -o /tmp/lsh_less_keys_tmp -- - &> /dev/null
fi
function get_containers() {
    ELT="$(echo "${CONTAINER_UNCOL[$CURRENT_POS-1]}")"
    #extract hash_container started from 8 - 10 characters
    CONTAINER_HASH=${ELT:8:10}
#    INSPECT_DOCKER="docker container inspect $CONTAINER_HASH"
#                    --format \"table IpAdress   : {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\n      \
#                               MacAdress  : {{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}} \n    \
#                               PathLog    : {{.LogPath}}\n                                                  \
#                               ImageName  : {{.Config.Image}} \n                                            \
#                               StartedAt  : {{.State.StartedAt}}\n                                          \
#                               FinishedAt : {{.State.FinishedAt}}\n                                         \
#                               Status     : {{.State.Status}}\" "
    INSPECT_DOCKER="docker container diff $CONTAINER_HASH"
    CONTAINER=$(eval ${INSPECT_DOCKER} 2>/dev/null)
    tmp_diff="$(echo "$CONTAINER" | $SED_CMD)"
    off=$(echo "$tmp_diff" | grep -c ".\{$CN\}")
    DIFF_LINES_NUMBER="$(echo "$CONTAINER" | wc -l)"
    DIFF_LINES_NUMBER=$(( DIFF_LINES_NUMBER + off ))
}

function set_containers() {
    get_containers
    if [[ $(( LINE_USED + DIFF_LINES_NUMBER + OFFSET )) -ge $(( `tput lines` - 1 )) ]]; then
	trap - INT
	if [[ $LESSKEY = true ]]; then
	    echo "$CONTAINER" | less -r -k /tmp/lsh_less_keys_tmp
	else 
	    echo "$CONTAINER" | less -r
	fi
	trap cleanup INT
	cls
    else 
	stop=false
	cls
	for i in `seq 1 $LINE_USED`
	do
	    echo -n "$NORMAL"
	    [[ $CURRENT_POS == "$i" ]] && echo -n "$REVERSE"
	    echo "${DOCKER[$i - 1]}"
	    [[ $CURRENT_POS == "$i" ]] && echo "$CONTAINER"
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
		    END=true
		    ;;
	    esac
	done
	[[ $END = false ]] && tput cuu $(( LINE_USED + DIFF_LINES_NUMBER + OFFSET )) && cls
    fi
}

function calculate_offset {
    tmp=1
    index=$(( INDEX -1 ))
    while [[ $tmp -lt $SN ]]
    do
    	el=${CONTAINER_UNCOL[$index]}
    	if [[ ${#el} -gt $CN ]] && [[ $CURRENT_POS -lt $((SN -1)) ]]; then
    	    OFFSET_2=$(( OFFSET_2 + 1 ))
    	    tmp=$(( tmp + 1 ))
    	fi
    	tmp=$(( tmp + 1 ))
    	index=$(( index + 1 ))
    done
}
function cleanup() {
    [[ $LESSKEY = true ]] && rm /tmp/lsh_less_keys_tmp

    tput cuu 1
    tput cnorm
    echo "$NORMAL"
    stty "$orig_stty" > /dev/null 2>&1
    exit
}

trap cleanup INT

{


while ! $END
do
    END_INDEX=0
    if [[  $LINE_USED == $CONTAINER_INDEX ]]; then 
	END_INDEX=$LINE_USED
	OFFSET_2=$OFFSET
    elif [[  $LINE_USED == $(( SN - 1 )) ]]; then
	if [[ $OFFSET != 0 ]]; then 
   	    [[ $CURRENT_POS -lt $((SN -1)) ]] && OFFSET_2=0
   	    EXT=1
   	    calculate_offset
	fi
	END_INDEX=$(( LINE_USED + INDEX -1 + EXT - OFFSET_2 ))
    fi

    for i in `seq $INDEX $END_INDEX`
    do
	echo -n "$NORMAL"
	[[ $CURRENT_POS == $i ]] && echo -n "$REVERSE"
	echo "${DOCKER[$i - 1]}"
    done

    read -sn 1 key
    [[ "$key" == "$ec" ]] &&
    {
	read -sn 2 k2
	key="$key$k2"
    }

    case "$key" in
	"$ArrowUp" | "$ArrowUp_1")
            CURRENT_POS=$(( CURRENT_POS - 1 ))
            [[ $CURRENT_POS == 0 ]] && [[ $INDEX == 1 ]] && [[ $LINE_USED == $(( SN - 1 )) ]] && CURRENT_POS=$CONTAINER_INDEX && INDEX=$(( CONTAINER_INDEX - SN + 2 + OFFSET_2 ))
            [[ $CURRENT_POS == 0 ]] && [[ $INDEX == 1 ]] && [[ $LINE_USED == $CONTAINER_INDEX ]] && CURRENT_POS=$LINE_USED
            [[ $CURRENT_POS == $(( INDEX - 1 )) ]] && [[ $INDEX != 1 ]] && INDEX=$(( INDEX - 1 ))

   	    [[ $LINE_USED != $(( SN - 1 )) ]] && tput cuu $(( LINE_USED + OFFSET_2 ))
   	    [[ $LINE_USED == $(( SN - 1 )) ]] && tput cuu $(( LINE_USED + EXT ))
            [[ $INDEX != 1 ]] && cls
            ;;
	"$ArrowDown" | "$ArrowDown_1")
   	    CURRENT_POS=$(( CURRENT_POS + 1 ))
            [[ $CURRENT_POS == $(( CONTAINER_INDEX + 1 )) ]] && CURRENT_POS=1 && INDEX=1 
            [[ $CURRENT_POS == $(( SN + INDEX - 1 + EXT - OFFSET_2 )) ]] && [[ $LINE_USED == $(( SN - 1 )) ]] && INDEX=$(( INDEX + 1 ))

   	    [[ $LINE_USED != $(( SN - 1 )) ]] && tput cuu $(( LINE_USED + OFFSET_2 ))
   	    [[ $LINE_USED == $(( SN - 1 )) ]] && tput cuu $(( LINE_USED + EXT ))
            [[ $INDEX != 1 ]] && cls
            [[ $INDEX = 1 ]] && [[ $CURRENT_POS = 1 ]] && cls
            ;;
	"$nl" | "$nl_1")
   	    [[  $LINE_USED == $CONTAINER_INDEX ]] && tput cuu $(( LINE_USED + OFFSET_2 ))
   	    [[  $LINE_USED != $CONTAINER_INDEX ]] && tput cuu $(( LINE_USED + EXT ))
            set_containers 
            ;;
	"q")
            INDEX=false
            END=true
            ;;
	* )
   	    tput cuu $(( LINE_USED + OFFSET_2 ))
    esac
done

cleanup

} >&2