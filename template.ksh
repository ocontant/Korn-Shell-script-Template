#!/bin/ksh
################################################################
# Script to [template]
# Copyright (C) 2013 Olivier Contant - All Rights Reserved
# Permission to copy and modify is granted
# Last revised 2013/07/24

set -e # Stop and exit on error if not handled by the scripts

#   
# -----------------------------------------------------------------------------
#
#   usage - Display the program usage 
# 
# -----------------------------------------------------------------------------

function f_usagemsg {
  print "
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
################################################################
#### 
#### Description:
#### 
#### Place a full text description of your shell function here.
#### 
#### Assumptions:
#### 
#### Provide a list of assumptions your shell function makes,
#### with a description of each assumption.
#### 
#### Dependencies:
#### 
#### Provide a list of dependencies your shell function has,
#### with a description of each dependency.
#### 
#### Products:
#### 
#### Provide a list of output your shell function produces,
#### with a description of each product.
#### 
#### Configured Usage:
#### 
#### Describe how your shell function should be used.
#### 
#### Details:
#### 
#### Place nothing here, the details are your shell function.
#### 
################################################################


  typeset version="1.1"
  typeset date=`date "+%Y-%m-%d"`
  typeset scriptname=`basename $0`
  typeset true="1"
  typeset false="0"
  typeset verbose="${false}"
  typeset veryverb="${false}"
  typeset debug="${false}"                  # Use with (( debug == true )) && echo "DEBUG TEXT"
  typeset logfile                           # To define the location and filename of where we want to log the execution of this script
  typeset errorfile                         # To define the location and filename of where we want to log the execution of this script
  typeset pid=$$                            # The main process ID instance of our script
  typeset rc                                # Return Command executing code handling
  typeset tmpfile=${TMPDIR:-/tmp}/prog.$$   # temp filename will be /tmp/prog.$$.X or variable name $tmpfile.X
  typeset counter=0
  
  
 ### If we need logfile
 # exec >> $LOGFILE
 
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
          #'a') required_optarg=${OPTARG};;
          #'b') b_var="${true}";;
          'D') debug="${true}";;
          'h') usage ;;
          'v') verbose="${true}";;
          'V') veryverb="${true}";;
          '?') f_usagemsg "${0}" && return 1 ;;
          ':') f_usagemsg "${0}" && return 1 ;;
          '#') f_usagemsg "${0}" && return 1 ;;
      esac
  done
   
  shift $(( ${OPTIND} - 1 ))
  
    (( veryverb == true )) && set -x
    (( verbose  == true )) && print -u 2 "# Version........: ${version}" && exit 0
    
  trap "usagemsg ${0}" EXIT
    
    #### Place any command line option error checking statements
    #### here.  If an error is detected, print a message to
    #### standard error, and return from this function with a
    #### non-zero return code.  The "trap" statement will cause
    #### the "usagemsg" to be displayed.
    #### Ex.:  [[ -z $required_optarg || $required_optarg = -* ]] && f_error ERROR 125 " " && echo "-a value is: ${required_optarg}" && exit 125
    
  trap "-" EXIT  # Disable the trap for EXIT
  
  return 0
}

# -----------------------------------------------------------------------------
#
#   log_success_msg - Print nice success message
#
# -----------------------------------------------------------------------------
function log_success_msg {
   success "$*"; echo -e "\r\n"$*"\r\n"; 
}

# -----------------------------------------------------------------------------
#
#   log_failure_msg - Print nice failure message
#
# -----------------------------------------------------------------------------
function log_failure_msg {
  failure "$*"; echo -e "\r\n"$*"\r\n";
}

# -----------------------------------------------------------------------------
#
#   log_warning_msg - Print nice warning message
#
# -----------------------------------------------------------------------------
function log_warning_msg {
   warning "$*"; echo -e "\r\n"$*"\r\n";
}

# -----------------------------------------------------------------------------
#
#   f_kill - Kill process 
#
# -----------------------------------------------------------------------------
function f_kill  #$1=killsig $2=pid
{
    killsig=$1
    pid=$2  
    counter=0
    
    if [[ `ps -p $pid` ]]; then
        ## SENDING KILL SIGNAL.
        echo -ne $"Stopping $SCRIPTNAME."   
        kill -$killsig
        
        while [[ $counter -le 4 ]]
        do
            if [[ $counter -ne 4 ]]; then
                if [[ `ps -p $pid` ]]; then
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
                echo -ne "Killing SIGKILL $scriptname."
                kill -9 $pid
                if [[ `ps -p $pid` ]]; then
                    log_failure_msg "Unable to SIGKILL $scriptname."
                else
                    log_success_msg
                    break
                fi
            fi
        done
    else
        echo "INFO: $scriptname doesn't seem to be running at this moment. Cannot find PID." 
    fi  
}
# -----------------------------------------------------------------------------
#
#   f_error - Print meaningful error messages
#
# -----------------------------------------------------------------------------
function f_error #$1=errortype&errornum&message
{
    # [[ ! -z "$debug" ]] && set -x
     
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
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            echo -n "Core Dump available:";
            trap '-' EXIT SIGABRT
            kill -SIGABRT $pid;;
        011) erm="${ert}: Terminated by signal SIGSEGV";
            [[ ! -z tmpfile ]] && rm -f ${tmpfile}
            echo "$erm"
            echo "@@@@@@@@@@@@@@@@@@@@"
            echo ""
            echo -n "Core Dump available:";
            trap '-' EXIT SIGSEGV
            kill -SIGSEGV $pid;;
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

    
    ######## Example of usage of error function
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
#   BEGINNING OF THE SCRIPT EXECUTION
#
# -----------------------------------------------------------------------------

### Trapping exiting code ###
trap 'f_error ERROR 001 HUP; trap - HUP' HUP
trap 'f_error ERROR 002 INT; trap - INT' INT
trap 'f_error ERROR 003 QUIT; trap - QUIT' QUIT
trap 'f_error ERROR 006 SIGABRT; trap - SIGABRT' SIGABRT
trap 'f_error ERROR 011 SIGSEGV; trap - SIGSEGV' SIGSEGV
trap 'f_error ERROR 015 TERM; trap - TERM' TERM
trap 'f_error ERROR 127 EXIT; trap - EXIT' EXIT


# -----------------------------------------------------------------------------
#
#   LOADING OUR PARAMETER PARSER 
#
# ----------------------------------------------------------------------------- 

##########################################
### Pass our parameter and do validation #
##########################################

### Validate if we have at least one parameter for our getops
if [[ $# -eq 0 ]]
then
    f_error ERROR 124 "$#=0" # ERROR 124 No command line arguments supplied
    f_usagemsg "${0}"
    exit 124
fi  

### Pass our parameter and do validation 
f_get_parameter "${@}"


# -----------------------------------------------------------------------------
#
#   THE REST OF THE ALGORYTHME GOES HERE  
#
# ----------------------------------------------------------------------------- 








