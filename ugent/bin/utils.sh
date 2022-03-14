readonly base=`basename $0`
readonly LOCK_FD=200

eexit() {
    local error_str="$@"
    logger "$error_str" "ERROR" >&2
    exit 1
}
lock() {
    local prefix=$base
    local fd=${2:-$LOCK_FD}
    local lock_file=tmp/$base.lock

    # create lock file
    eval "exec $fd>$lock_file"

    logger "trying to retrieve exclusive lock on $lock_file (non blocking)" "DEBUG"

    # acquier the lock
    flock -n $fd && return 0 || return 1
}
lock_wait() {
    local prefix=$base
    local fd=${2:-$LOCK_FD}
    local lock_file=tmp/$base.lock

    # create lock file
    eval "exec $fd>$lock_file"
    logger "waiting to retrieve exclusive lock on $lock_file (blocking)" "DEBUG"

    # acquier the lock
    flock -x $fd && return 0 || return 1
}
lock_file() {

    lock || eexit "Only one instance of $base can run at one time"
    logger "received exclusive lock" "DEBUG"

}
lock_wait_file() {

    lock_wait
    logger "received exclusive lock" "DEBUG"

}
logger() {

    local str=$1
    local level=$2

    if [ -z "$level" ];then
        level="INFO"
    fi

    local d=$(date +"%Y/%m/%d %H:%M:%S")

    echo "[$d] [$$] $0 $level - $str"

}
