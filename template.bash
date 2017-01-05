#!/bin/bash
################################################################
# Script to [template]
# Copyright (C) 2013 Olivier Contant - All Rights Reserved
# Permission to copy and modify is granted
# Last revised 2017/01/05

#set -e # Stop and exit on error if not handled by the scripts

#
# -----------------------------------------------------------------------------
#
#   usage - Display the program usage
#
# -----------------------------------------------------------------------------
function f_usagemsg {
  printf "
Program: your_function

Place a brief description ( < 255 chars ) of your shell
function here.

Usage: ${1##*/} [-?(a)(b)DvV]
** Where ( ) are mandatory options

  Where:
    -D = Debug mode - Display special text for debugging purpose
    -v = Verbose mode - displays your_function function info
    -V = Very Verbose Mode - debug output displayed
    -? = Help - display this message

Author: Olivier Contant (contant.olivier@gmail.com)
\"AutoContent\" enabled
"
}

###
# Source function library for RedHat based system..
. /etc/rc.d/init.d/functions
#
# Function description available in /etc/rc.d/init.d/functions
# success/failure: Logging functions to track any errors that may occour.
# echo_failure/echo_success: Outputs either [FAILED] or [OK] in Red or Green lettering on the right of the terminal
# pidofproc: a function to get the PID of a program when given the path to the executable
# killproc: a function to kill a program when given the path to the executable
###

################################################################
####
#### Description:
####
####
#### Assumptions:
####
####
#### Dependencies:
####
####
#### Output :
####
####
################################################################


   version="1.0"
   date=`date "+%Y-%m-%d"`
   scriptname=`basename $0`
   true='1'
   false='0'
   verbose="${false}"
   veryverb="${false}"
   debug="${false}"                             # Use with (( DEBUG == TRUE )) && echo "DEBUG TEXT"
   logfile=''                                   # To define the location and filename of where we want to log the execution of this script
   errorfile=''                                 # To define the location and filename of where we want to log the execution of this script
   pid=$$                                       # The main process ID instance of our script
   rc=''                                        # Return Command executing code handling
   tmpfile=${TMPDIR:-/tmp}/prog.$$              # temp filename will be /tmp/prog.$$.X or variable name $tmpfile.X
   counter=0

 ### If we need global logfile
#exec >> $LOGFILE


# -----------------------------------------------------------------------------
#
# Function Definitions
#
# -----------------------------------------------------------------------------

function f_get_parameter
{
 while getopts ":a:bDhvV" OPTION
 do
     case "${OPTION}" in
   'a') required_optarg=${OPTARG};;
   'b') b_var="${TRUE}";;
   'D') debug="${TRUE}";;
   'h') f_usagemsg ;;
         'v') verbose="${TRUE}";;
         'V') veryverb="${TRUE}";;
         '?') f_usagemsg "${0}" && return 1 ;;
         ':') f_usagemsg "${0}" && return 1 ;;
         '#') f_usagemsg "${0}" && return 1 ;;
     esac
 done

 shift $(( ${OPTIND} - 1 ))

   (( veryverb == TRUE )) && set -x
 (( verbose  == TRUE )) && print -u 2 "# Version........: ${version}" && exit 0

 return 0
}

# -----------------------------------------------------------------------------
#
#   Simple function to display separator character on the size of terminal width
#
# -----------------------------------------------------------------------------
function f_print_separator
{
        for i in `seq 1 79`;do printf '*'; done
        printf '%s\n' "*"
}

# -----------------------------------------------------------------------------
#
#   log_success_msg - Print nice success message
#
# -----------------------------------------------------------------------------
 log_success_msg () {
   success "$*"; echo -e "\r\n"$*"\r\n";

}

# -----------------------------------------------------------------------------
#
#   log_failure_msg - Print nice failure message
#
# -----------------------------------------------------------------------------
 log_failure_msg () {
  failure "$*"; echo -e "\r\n"$*"\r\n";
}

# -----------------------------------------------------------------------------
#
#   log_warning_msg - Print nice warning message
#
# -----------------------------------------------------------------------------
 log_warning_msg () {
   warning "$*"; echo -e "\r\n"$*"\r\n";
}

# -----------------------------------------------------------------------------
#
#   f_kill - Kill process
#
# -----------------------------------------------------------------------------
 f_kill  () #$1=KILLSIG $2=PID
{
    KILLSIG=$1
    PID=$2
    counter=0

    if [[ `ps -p $PID` ]]; then
        ## SENDING KILL SIGNAL.
        echo -ne $"Stopping $SCRIPTNAME."
        kill -$KILLSIG $PID

        while [[ $counter -le 4 ]]
        do
            if [[ $counter -ne 4 ]]; then
                if [[ `ps -p $PID` ]]; then
                    echo -ne "\r\n ... Waiting for process to terminate."
                    (( counter++ ))
                    sleep 4
                else
                    log_success_msg
                    break
                fi
            else
                log_failure_msg "Failed to terminated the process."

                ## SENDING KILL SIGNAL.
                echo -ne "Killing SIGKILL $SCRIPTNAME."
                kill -9 $PID
                if [[ `ps -p $PID` ]]; then
                    log_failure_msg "Unable to SIGKILL $SCRIPTNAME."
                else
                    log_success_msg
                    break
                fi
            fi
        done
    else
        echo "INFO: $SCRIPTNAME doesn't seem to be running at this moment. Cannot find PID."
    fi
}

# -----------------------------------------------------------------------------
#
#   f_error - Print meaningful error messages
#
# -----------------------------------------------------------------------------
 f_error () #$1=errortype&errornum&message
{
    # [[ ! -z "$DEBUG" ]] && set -x

    dtg=`date +%D\ %H:%M:%S`
    if [[ ! "$1" = "" ]];then
        errortype=$1; shift
        errornum=$1; shift
        errormsg=$1; shift
    fi

    echo ""
    echo "@@@@ $errortype: $errornum @@@@"
    ert="$dtg: $scriptname: $errortype"
    case $errornum in
        000) erm="${ert}: Normal Termination ${errormsg}"
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
   	    echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT
            exit 0;;
        001) erm="${ert}: Terminated by signal HUP";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT HUP
            f_kill 'HUP' $pid;;
        002) erm="${ert}: Terminated by signal INT";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT INT
            kill -INT $pid;;
        003) erm="${ert}: Terminated by signal QUIT";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT QUIT
            f_kill 'QUIT' $pid;;
        006) erm="${ert}: Terminated by signal SIGABRT";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo ""
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            echo -n "Core Dump available: $coredumppath/";ls $coredumppath|grep $$
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            f_get_coredump $pid $binary $coredumppath
            echo ""
            echo ""
            echo ""
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT SIGABRT
            f_Skill 'SIGABRT' $PID;;
        011) erm="${ert}: Terminated by signal SIGSEGV";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo ""
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            echo -n "Core Dump available: $coredumppath/";ls $coredumppath|grep $$
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            f_get_coredump $pid $binary $coredumppath
            echo ""
            echo ""
            echo ""
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT SIGSEGV
            f_kill 'SIGSEGV' $PID;;
        015) erm="${ert}: Terminated by signal TERM";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT TERM
            f_kill 'TERM' $pid;;
        124) erm="${ert}: No command line arguments supplied";;
        125) erm="${ert}: Invalid command line flag. ${ERRORMSG}";;
        126) erm="${ert}: File or Directory $ERRORMSG doesn't exist!"; rc=1;;
        127) erm="${ert}: Script exiting!";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            trap '-' EXIT
            exit;;
            #f_kill 'EXIT' $PID;; ## Bug to fix, loop on exit
        *) erm="${ert}: Unallocated error ............$errornum";;
    esac
    echo ""
    echo "$erm"
    echo ""
    echo "@@@@@@@@@@@@@@@@@@@@"
    echo ""
    echo ""


    ######## Example of usage of error
    ### 1. f_error INFO 000 (at end of script after normal execution
    ###
    ### 2. f_error ERROR 124
    ###    usage
    ###      exit 124
    ###
    ### 3. trap 'f_error ERRROR 001' HUP INT QUIT TERM
    ###
    ### Make sure when trapping exiting signal to kill the process also
    ### [[ ! -z tmpfile ]] && rm -f ${tmpfile}
    ### kill -[SIG_TRAPPED] $PID;;
}

# -----------------------------------------------------------------------------
#
#   f_utc_to_est - Convert UTC time into EST timezone
#
# -----------------------------------------------------------------------------
f_utc_to_est ()
{
    filename=$1
    timefromfile=`echo $1|cut -d'.' -f 6`
    timeutc=`echo "${timefromfile#?}"`
    date -d @$timeutc
}

# -----------------------------------------------------------------------------
#
#   f_send_email - Send email HTML format
#
# -----------------------------------------------------------------------------
f_send_email () #$1=mailfrom $2=mailto $3=subject $4=body $5=attach
{
	mailfrom=$1
	mailto=$2
	subject=$3
	body=$4
	attach=$5
	mailpart=`uuidgen` ## Generates Unique ID
	mailpart_body=`uuidgen` ## Generates Unique ID

	(
	 echo "From: $mailfrom"
	 echo "To: $mailto"
	 echo "Subject: $subject"
	 echo "MIME-Version: 1.0"
	 echo "Content-Type: multipart/mixed; boundary=\"$mailpart\""
	 echo ''
	 echo "--$mailpart"
	 echo "Content-Type: multipart/alternative; boundary=\"$mailpart_body\""
	 echo ''
	 echo "--$mailpart_body"
	 echo 'Content-Type: text/plain; charset=ISO-8859-1'
	 echo 'You need to enable HTML option for email'
	 echo "--$mailpart_body"
	 echo 'Content-Type: text/html; charset=ISO-8859-1'
	 echo 'Content-Disposition: inline'
	if [[ -f $body ]]; then
		cat "$body"
	else
		echo "$body"
	fi
	 echo "--$mailpart_body--"

	 echo "--$mailpart"
	 echo 'Content-Type: application/octet-stream; name='"$(basename $attach)"
	 echo 'Content-Transfer-Encoding: base64'
	 echo 'Content-Disposition: attachment; filename='"$(basename $attach)"
	 echo ''
	 echo "$(perl -MMIME::Base64 -e 'open F, shift; @lines=<F>; close F; print MIME::Base64::encode(join(q{}, @lines))' $attach)"
	 echo "--$mailpart--"
	 ) | /usr/sbin/sendmail $mailto

}


# -----------------------------------------------------------------------------
#
#   BEGINNING OF THE SCRIPT
#
# -----------------------------------------------------------------------------


#############################
### Trapping exiting code ###
#############################
trap 'f_error ERROR 001 HUP; trap - HUP' HUP
trap 'f_error ERROR 002 INT; trap - INT' INT
trap 'f_error ERROR 003 QUIT; trap - QUIT' QUIT
trap 'f_error ERROR 006 SIGABRT; trap - SIGABRT' SIGABRT
trap 'f_error ERROR 011 SIGSEGV; trap - SIGSEGV' SIGSEGV
trap 'f_error ERROR 015 TERM; trap - TERM' TERM

#Example trap for when you want to exit using the exit command.  It will trap any exit command to display a meaningful message:
# trap 'f_error ERROR 000 EXIT; trap - EXIT' EXIT

# -----------------------------------------------------------------------------
#
#   LOADING OUR PARAMETER PARSER
#
# -----------------------------------------------------------------------------

### Validate if we have at least one parameter for our getops
if [[ $# -eq 0 ]]
then
	f_error ERROR 124 "ERROR 124 No command line arguments supplied"
	f_usagemsg "${0}"
	exit 124
fi

### Pass our parameter and do validation
f_get_parameter "${@}"

#
#### Place any passed arguments error checking statements here
#### If an error is detected, print a message to
#### standard error.  Then exit with the error code 125 and display usagemsg
####
#### Ex.:  [[ -z $required_optarg ]] && f_error ERROR 125 "Description Error" && echo "-a value is: ${required_optarg}" && exit 125
#


# -----------------------------------------------------------------------------
#
#   THE REST OF THE ALGORYTHME GOES HERE
#
# -----------------------------------------------------------------------------

### Display some environment variable
[[ -f $logfile ]] && echo "Log will be written in ${logfile}"
[[ -f $errorfile ]] && echo "error log will be written in ${errorfile}"
[[ -f $tmpfile ]] && echo "tmpfile is located in ${tmpfile}"
echo "The pid of this process is $$"

###############################
#### Write your code here #####
###############################

# -----------------------------------------------------------------------------
#
#   If everything else ran successfully
#
# -----------------------------------------------------------------------------
f_error INFO 000 "${scriptname} executed succesfully"
