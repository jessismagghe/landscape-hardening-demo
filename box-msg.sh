# Thank you to Craig Bender for this box formatting function 

box-msg() {
    local DESC="\e[2G${FUNCNAME}: Displays a string in a box.\n"
    local STYLE="double"
    local PAD=2
    box-msg_usage() {
            printf "${DESC}\n\n"
            printf "\n\e[2GUsage: ${FUNCNAME%%_*} [ Options ] \"text\"\n\n"
            printf "\nOptions:\n\n"
            printf "\e[2G -s, --style \e[28GOptional: Style of box.  r|round, s|square, d|double\n"
            printf "\e[28GDefault: ${STYLE}\n"
            for i in square round double;do box-msg -s $i $i;done
            printf "\e[28GNote: Seamless alignment of box elements is heavily dependent on font.\n\n"
            printf "\e[2G -p, --pad \e[28GPad string n spaces from vertical sides of box\n"
            printf "\e[28GDefault: ${PAD}\n\n"
            
            printf "\e[28GTip: Protect special characters by single quoting message string\n\n"
            }
    ARGS=`getopt -o s:p:dh -l style:,pad:,desc,help -n ${FUNCNAME} -- "$@"`
    eval set -- "$ARGS"
    while true ; do
        case "$1" in
            -s|--style) local STYLE=${2,,};shift 2;;
            -p|--pad) local PAD=${2};shift 2;;
            -d|--desc) printf "${DESC}";return 2;;
            -h|--help) ${FUNCNAME}_usage;return 2;;
            --) shift;break;;
        esac
    done
    if [[ ${STYLE} = r || ${STYLE} = round ]];then
        local HC=$(printf '\u2500')
        local VC=$(printf '\u2502')
        local ULC=$(printf '\u256D')
        local URC=$(printf '\u256E')
        local LLC=$(printf '\u2570')
        local LRC=$(printf '\u256F')
    elif [[ ${STYLE} = s || ${STYLE} = square ]];then
        #Square Corners UTF8 Box Drawing Characters
        local HC=$(printf '\u2501')
        local VC=$(printf '\u2503')
        local ULC=$(printf '\u250F')
        local URC=$(printf '\u2513')
        local LLC=$(printf '\u2517')
        local LRC=$(printf '\u251B')
    elif [[ ${STYLE} = d || ${STYLE} = double ]];then
        local HC=$(printf '\u2550') # ═
        local VC=$(printf '\u2551') # ║
        local ULC=$(printf '\u2554') # ╔
        local URC=$(printf '\u2557') # ╗
        local LLC=$(printf '\u255A') # ╚
        local LRC=$(printf '\u255D') # ╝
    fi
    [[ ${PAD} =~ ^[0-9]+$ ]] || { printf "\e[2GThe pad option must be a number\n";return 1; }
    local PADSTR="$(eval printf "\\#%0.0s" {0..${PAD}})"
    local STR=$(echo "$@"|sed -E 's/^ | $//g;s/^.|$/'${PADSTR}'&/g')
    local SLONG=$(printf "$STR"|awk '{gsub(/\x1B\[[0-9;]*[a-zA-Z]|\x1B\[[0]m$/,"");print length()| "sort -rn|head -n 1"}')
    local SSHORT=$(printf "$STR"|awk '{gsub(/\x1B\[[0-9;]*[a-zA-Z]|\x1B\[[0]m$/,"");print length()| "sort -n|head -n 1"}')
    eval printf "%.3s%.3s%.3s" ${ULC}{1..1} ${HC}{0..$(echo ${SLONG})} ${URC}{1..1}
    while IFS= read L;do
        LLEN=$(echo "$L"|wc -L)      
        if [[ ${LLEN} -lt ${SLONG} ]];then             
            printf "\n${VC}${L}$(eval printf "\\#%0.0s" {0..$(($SLONG-${LLEN}))})${VC}"|sed -E 's/#/ /g'
        else
            printf "\n${VC}${L}${VC}"|sed -E 's/#/ /g;s/.$/ &/g'
        fi
    done < <(printf "$STR"|awk '{gsub(/\x1B\[[0-9;]*[a-zA-Z]|\x1B\[[0]m$/,"");print $0}')
    echo
    eval printf "%.3s%.3s%.3s" ${LLC}{1..1} ${HC}{0..$(echo ${SLONG})} ${LRC}{1..1}
    printf '\n'
};export -f box-msg