print_space() {
    local _space_n=$1
    local i=0
    while [ $((i++)) -lt ${_space_n:=1} ]; do printf ' '; done
}

color_echo() {
    local _reset='\e[0m'
    local _n=$1 && shift
    case "$_n" in
    [0-6]) printf '\e[3%sm%b%b' "$_n" "$*" "$_reset" ;;
    7 | "fg") printf '\e[37m%b%b' "$*" "$_reset" ;;
    *) printf '\e[38;5;%bm%b%b' "$_n" "$*" "$_reset" ;;
    esac
}

color_print() {
    [ $# -le 0 ] && echo 'arguments less than zero' && return 1
    local inf_lv=$1
    shift
    local info="$*"
    case $inf_lv in
    -i | --info) printf "%s$(color_echo 4 %s %b)\n" '📨' '=>' "$info" ;;
    -s | --sucess) printf "%s$(color_echo 2 %s %b)\n" '✔️' '+>' "$info" ;;
    -w | --warn) printf "%s$(color_echo 3 %s %b)\n" '🚨' '!>' "$info" ;;
    -e | --error) printf "%s%s$(color_echo 1 %s %b)\n" '❌' 'x>' "$info" ;;
    *)
        info=$inf_lv
        printf "%s%s$(color_echo fg %s %b)\n" '❓' '?>' "$info"
        ;;
    esac
}

hint(){
    color_print -i "$* -> Press any key to continue..."
    # read _rubbish
}

cpu_cores() { # acquires logical cores of CPU
    # works for Linux MINIX Windows /proc/cpuinfo
    grep -c "^processor" "/proc/cpuinfo"
    # 可用 nproc 命令取代？但 BSD 系统没有 nproc
}

filename_prefix() { # "$@" URL or file path
    basename "$*" |
        sed -E 's/\.tar.*$//g' |
        sed -E 's/\.zip$//g' |
        sed -E 's/\.git$//g' |
        sed -E 's/\.t[gx]z*$//g' |
        sed -E 's/\.7z$//g'
}

smart_clone() {
    local _url=$1
    local _name_prefix=${3:-$(filename_prefix "$_url")}
    local repo_d=${2:-"$(pwd)"}/"$_name_prefix"
    # local src_d=${3:-$repo_d}

    color_print -i "Clone $_url into $repo_d"
    if [ ! -d "$repo_d" ]; then
        git clone --recursive "$_url" "$repo_d"; _err=$?
    else
        git -C "$repo_d" pull --recurse-submodules=yes; _err=$?
    fi
    # if [ $_err -ne 0 ]; then
    #     color_print -e "Git ERROR, try to re-clone all repo"
    #     \rm -rf "$repo_d"
    #     git clone --recursive "$_url" "$repo_d"
    # fi
}
