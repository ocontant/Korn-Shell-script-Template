#!/bin/bash
#
# <service> <Brief Description>
#
# chkconfig: <runlevels> <start_number> <kill_number>
# description: <More detailed description of the service>
# processname: <process_name>


### Make sure umask is sane
umask 022

### Set up a default search path.
PATH="/sbin:/usr/sbin:/bin:/usr/bin"
export PATH

# Get a sane screen width
[ -z "${COLUMNS:-}" ] && COLUMNS=80
[ -z "${CONSOLETYPE:-}" ] && CONSOLETYPE="`/sbin/consoletype`"

if [ -f /etc/sysconfig/i18n -a -z "${NOLOCALE:-}" ] ; then
  . /etc/profile.d/lang.sh
fi

### Anything else => new style bootup without ANSI colors or positioning
BOOTUP=color
### Column to start "[  OK  ]" label in
RES_COL=60
### Terminal sequence to move to that column.
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
### Terminal sequence to set color to a 'success' color (currently: green)
SETCOLOR_SUCCESS="echo -en \\033[0;32m"
### Terminal sequence to set color to a 'failure' color (currently: red)
SETCOLOR_FAILURE="echo -en \\033[0;31m"
### Terminal sequence to set color to a 'warning' color (currently: yellow)
SETCOLOR_WARNING="echo -en \\033[0;33m"
### Terminal sequence to reset to the default color.
SETCOLOR_NORMAL="echo -en \\033[0;39m"

# Declare some useful functions
echo_success() {
	[ "$BOOTUP" = "color" ] && $MOVE_TO_COL
	echo -n "["
	[ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
	echo -n $"  OK  "
	[ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
	echo -n "]"
	echo -ne "\r"
	echo ""
	return 0
}

echo_failure() {
	[ "$BOOTUP" = "color" ] && $MOVE_TO_COL
	echo -n "["
	[ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
	echo -n $"FAILED"
	[ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
	echo -n "]"
	echo -ne "\r"
	echo ""
	return 1
}

echo_passed() {
	[ "$BOOTUP" = "color" ] && $MOVE_TO_COL
	echo -n "["
	[ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
	echo -n $"PASSED"
	[ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
	echo -n "]"
	echo -ne "\r"
	return 1
}

echo_warning() {
	[ "$BOOTUP" = "color" ] && $MOVE_TO_COL
	echo -n "["
	[ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
	echo -n $"WARNING"
	[ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
	echo -n "]"
	echo -ne "\r"
	return 1
}

# Check if any of $pid (could be plural) are running
checkpid() {
	local i

	for i in $* ; do
		[ -d "/proc/$i" ] && return 0
	done
	return 1
}

__pids_var_run() {
	local base=${1##*/}
	local pid_file=${2:-/var/run/$base.pid}

	pid=
	if [ -f "$pid_file" ] ; then
		local line p

		[ ! -r "$pid_file" ] && return 4 # "user had insufficient privilege"
		while : ; do
			read line
			[ -z "$line" ] && break
			for p in $line ; do
				[ -z "${p//[0-9]/}" -a -d "/proc/$p" ] && pid="$pid $p"
			done
		done < "$pid_file"

			if [ -n "$pid" ]; then
					return 0
			fi
		return 1 # "Program is dead and /var/run pid file exists"
	fi
	return 3 # "Program is not running"
}

__pids_pidof() {
	pidof -c -o $$ -o $PPID -o %PPID -x "$1" || \
	pidof -c -o $$ -o $PPID -o %PPID -x "${1##*/}"
}

# A function to stop a program.
killproc() {
	local RC killlevel= base pid pid_file= delay

	RC=0; delay=3
	# Test syntax.
	if [ "$#" -eq 0 ]; then
		echo $"Usage: killproc [-p pidfile] [ -d delay] {program} [-signal]"
		return 1
	fi
	if [ "$1" = "-p" ]; then
		pid_file=$2
		shift 2
	fi
	if [ "$1" = "-d" ]; then
		delay=$2
		shift 2
	fi
		

	# check for second arg to be kill level
	[ -n "${2:-}" ] && killlevel=$2

		# Save basename.
		base=${1##*/}

		# Find pid.
	__pids_var_run "$1" "$pid_file"
	RC=$?
	if [ -z "$pid" ]; then
		if [ -z "$pid_file" ]; then
			pid="$(__pids_pidof "$1")"
		else
			[ "$RC" = "4" ] && { failure $"$base shutdown" ; return $RC ;}
		fi
	fi

		# Kill it.
		if [ -n "$pid" ] ; then
				[ "$BOOTUP" = "verbose" -a -z "${LSB:-}" ] && echo -n "$base "
		if [ -z "$killlevel" ] ; then
			   if checkpid $pid 2>&1; then
			   # TERM first, then KILL if not dead
			   kill -TERM $pid >/dev/null 2>&1
			   usleep 100000
			   if checkpid $pid && sleep 1 &&
				  checkpid $pid && sleep $delay &&
				  checkpid $pid ; then
								kill -KILL $pid >/dev/null 2>&1
				usleep 100000
			   fi
				fi
			checkpid $pid
			RC=$?
			[ "$RC" -eq 0 ] && failure $"$base shutdown" || success $"$base shutdown"
			RC=$((! $RC))
		# use specified level only
		else
				if checkpid $pid; then
						kill $killlevel $pid >/dev/null 2>&1
				RC=$?
				[ "$RC" -eq 0 ] && success $"$base $killlevel" || failure $"$base $killlevel"
			elif [ -n "${LSB:-}" ]; then
				RC=7 # Program is not running
			fi
		fi
	else
		if [ -n "${LSB:-}" -a -n "$killlevel" ]; then
			RC=7 # Program is not running
		else
			failure $"$base shutdown"
			RC=0
		fi
	fi

		# Remove pid file if any.
	if [ -z "$killlevel" ]; then
			rm -f "${pid_file:-/var/run/$base.pid}"
	fi
	return $RC
}

# A function to find the pid of a program. Looks *only* at the pidfile
pidfileofproc() {
	local pid

	# Test syntax.
	if [ "$#" = 0 ] ; then
		echo $"Usage: pidfileofproc {program}"
		return 1
	fi

	__pids_var_run "$1"
	[ -n "$pid" ] && echo $pid
	return 0
}

# A function to find the pid of a program.
pidofproc() {
	local RC pid pid_file=

	# Test syntax.
	if [ "$#" = 0 ]; then
		echo $"Usage: pidofproc [-p pidfile] {program}"
		return 1
	fi
	if [ "$1" = "-p" ]; then
		pid_file=$2
		shift 2
	fi
	fail_code=3 # "Program is not running"

	# First try "/var/run/*.pid" files
	__pids_var_run "$1" "$pid_file"
	RC=$?
	if [ -n "$pid" ]; then
		echo $pid
		return 0
	fi

	[ -n "$pid_file" ] && return $RC
	__pids_pidof "$1" || return $RC
}

status() {
	local base pid lock_file= pid_file=

	# Test syntax.
	if [ "$#" = 0 ] ; then
		echo $"Usage: status [-p pidfile] {program}"
		return 1
	fi
	if [ "$1" = "-p" ]; then
		pid_file=$2
		shift 2
	fi
	if [ "$1" = "-l" ]; then
		lock_file=$2
		shift 2
	fi
	base=${1##*/}

	# First try "pidof"
	__pids_var_run "$1" "$pid_file"
	RC=$?
	if [ -z "$pid_file" -a -z "$pid" ]; then
		pid="$(__pids_pidof "$1")"
	fi
	if [ -n "$pid" ]; then
			echo $"${base} (pid $pid) is running..."
			return 0
	fi

	case "$RC" in
		0)
			echo $"${base} (pid $pid) is running..."
			return 0
			;;
		1)
					echo $"${base} dead but pid file exists"
					return 1
			;;
		4)
			echo $"${base} status unknown due to insufficient privileges."
			return 4
			;;
	esac
	if [ -z "${lock_file}" ]; then
		lock_file=${base}
	fi
	# See if /var/lock/subsys/${lock_file} exists
	if [ -f /var/lock/subsys/${lock_file} ]; then
		echo $"${base} dead but subsys locked"
		return 2
	fi
	echo $"${base} is stopped"
	return 3
}


## Function description available in /etc/rc.d/init.d/functions
# success/failure: Logging functions to track any errors that may occour.
# echo_failure/echo_success: Outputs either [FAILED] or [OK] in Red or Green lettering on the right of the terminal
# pidofproc: a function to get the PID of a program when given the path to the executable
# killproc: a function to kill a program when given the path to the executable
##

opts=''									# Arguments to script
execpath="Path to your executable"		# Path to your executable
prog=$(basename $execpath)				# binary program name

case "$1" in
    start)
    stop)
		if [ -n "`pidofproc $execpath`" ] ; then
			killproc $execpath
		else
			failure "Stopping <service>"
		fi
    status)
    restart)
    *)
esac