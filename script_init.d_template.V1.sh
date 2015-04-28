#!/bin/bash
#
# <service> <Brief Description>
#
# chkconfig: <runlevels> <start_number> <kill_number>
# description: <More detailed description of the service>
# processname: <process_name>
#
#
# Note: To add to chkconfig, copy the script to /etc/init.d and run : chkconfig --add <scriptname>


# Source function library.
. /etc/rc.d/init.d/functions
## Function description available in /etc/rc.d/init.d/functions
# success/failure: Logging functions to track any errors that may occour.
# echo_failure/echo_success: Outputs either [FAILED] or [OK] in Red or Green lettering on the right of the terminal
# pidofproc: a function to get the PID of a program when given the path to the executable
# killproc: a function to kill a program when given the path to the executable
##

# -----------------------------------------------------------------------------
#
# Variables definition 
#
# -----------------------------------------------------------------------------

opts=''									# Arguments to script
execpath="Path to your executable"		# Path to your executable
userexec=''								# User under which the daemon runs
prog=$(basename $execpath)				# binary program name
pidfile=/var/run/$(basename $execpath).pid


# -----------------------------------------------------------------------------
#
# Functions definition 
#
# -----------------------------------------------------------------------------
usage_msg() {
    echo "$0 <start|stop|restart|status>"
    exit 2
}
log_success_msg () {
   success "$*"; echo -e "\r\n"$*"\r\n"; 
}
log_failure_msg () {
  failure "$*"; echo -e "\r\n"$*"\r\n";
}
log_warning_msg () {
   warning "$*"; echo -e "\r\n"$*"\r\n";
}
f_start () {
	echo "start"
	echo -n $"Starting EMS ${ems_inst[$i]} Daemon: "
	## Check if $prog is running
	if [[ `pgrep -u ${userexec} -f "${execpath} ${opts}"` ]]; then
		log_failure_msg "$prog daemon is already running."
	else
		daemon --user $userexec $execpath $opts
		if [[ $rc -eq 0 ]]; then
			log_success_msg 
		else
			log_failure_msg "Return code: $rc"
		fi
	fi
}
f_stop () {
	if [[ `pgrep -u ${userexec} -f "${execpath} ${opts}"` ]]; then
		## SENDING TERM SIGNAL.
		echo -ne $"Stopping $prog Daemon: "	
		pkill -TERM -u $userexec -f "$execpath $options"
		
		if [[ $k -ne 4 ]]; then
			if [[ `pgrep -u ${userexec} -f "${execpath} ${opts}"` ]]; then
				echo -ne "\r\n ... Waiting for process to terminate."
				sleep 4
			else
				log_success_msg
				break
			fi
		else
			log_failure_msg "Failed to terminated the process."
			
			## SENDING KILL SIGNAL.
			echo -ne "Killing $prog Daemon: "
			pkill -KILL -u $userexec -f "$execpath $options"
			if [[ `pgrep -u ${userexec} -f "${execpath} ${opts}"` ]]; then
				log_failure_msg "Unable to KILL $prog Daemon."
			else
				log_success_msg
				break
			fi
		fi
		done
	else
		echo "$prog Daemon doesn't seem to be running at this moment." 
	fi	
}
f_status () {
	status $execpath
}

if [[ `whoami` != root ]]
	echo "You must be root to execute this script"
	exit 1
fi

### Make sure full path to executable binary is found
! [ -x $execpath ] && log_failure_msg "$execpath: executable not found" && exit 1


case "$1" in
    start) f_start;;
    stop) f_stop;;
    status) f_status;;
    restart)
			stop
			sleep 2
			start
	;;
    *) usage_msg;;
esac