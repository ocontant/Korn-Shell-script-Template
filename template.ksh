#!/usr/bin/ksh
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

'
  typeset VERSION="1.0"
  typeset DATE=`date "+%Y-%m-%d"`
  typeset SCRIPTNAME=`basename $0`
  typeset TRUE="1"
  typeset FALSE="0"
  typeset VERBOSE="${FALSE}"
  typeset VERYVERB="${FALSE}"
  typeset DEBUG="${FALSE}"					# Use with (( DEBUG == TRUE )) && echo "DEBUG TEXT"
  typeset LOGFILE							# To define the location and filename of where we want to log the execution of this script
  typeset ERRORFILE							# To define the location and filename of where we want to log the execution of this script
  typeset PID=$$							# The main process ID instance of our script
  typeset rc  								# Return Command executing code handling
  typeset tmpfile=${TMPDIR:-/tmp}/prog.$$  	# temp filename will be /tmp/prog.$$.X or variable name $tmpfile.X
  
  
  
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
		  'a') required_optarg=${OPTARG};;
		  'b') b_var="${TRUE}";;
		  'D') ${DEBUG}="${TRUE}";;
		  'h') usage ;;
          'v') VERBOSE="${TRUE}";;
          'V') VERYVERB="${TRUE}";;
          '?') usagemsg "${0}" && return 1 ;;
          ':') usagemsg "${0}" && return 1 ;;
          '#') usagemsg "${0}" && return 1 ;;
      esac
  done
   
  shift $(( ${OPTIND} - 1 ))
  
  	(( VERYVERB == TRUE )) && set -x
	(( VERBOSE  == TRUE )) && print -u 2 "# Version........: ${VERSION}" && exit 0
	
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
#   Message - Print meaningful error messages
#
# -----------------------------------------------------------------------------
function f_error #$1=errortype&errornum&message
{
    # [[ ! -z "$DEBUG" ]] && set -x
     
    dtg=`date +%D\ %H:%M:%S`
    if [[ ! "$1" = "" ]];then
        ERRORTYPE=$1; shift
        ERRORNUM=$1; shift
		ERRORMSG=$1; shift
    fi

    echo ""
    echo "@@@@ $ERRORTYPE: $ERRORNUM @@@@"
    ERT="$dtg: $SCRIPTNAME: $ERRORTYPE"
    case $ERRORNUM in
        000) ERM="${ERT}: Normal Termination${ERRORMSG}";;
        001) ERM="${ERT}: Terminated by signal HUP";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$ERM"
			kill -HUP $PID;;
		002) ERM="${ERT}: Terminated by signal INT";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$ERM"
			kill -INT $PID;;
		003) ERM="${ERT}: Terminated by signal QUIT";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$ERM"
			kill -QUIT $PID;;
	    015) ERM="${ERT}: Terminated by signal TERM";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$ERM"
			kill -TERM $PID;;
        124) ERM="${ERT}: No command line arguments supplied";;
        125) ERM="${ERT}: Invalid command line flag. ${ERRORMSG}";;
		126) ERM="${ERT}: File or Directory $ERRORMSG doesn't exist!"; rc=1;;
		127) ERM="${ERT}: Script exiting!";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$ERM"
			kill -TERM $PID;;
        *) ERM="${ERT}: Unallocated error ............$ERRORNUM";;
    esac
    echo ""
    echo "$ERM"
    echo ""
    echo "@@@@@@@@@@@@@@@@@@@@"
    echo ""
    echo ""

	
	######## Example of usage of error function
	### 1. f_error INFO 000 (at end of script after normal execution
	###
	### 2. f_error ERROR 124
	###    usage
	###  	 exit 124
	###
	### 3. trap 'f_error ERRROR 001' HUP INT QUIT TERM
	###
	### Make sure when trapping exiting signal to kill the process also
	### [[ ! -z tmpfile ]] && rm -f ${tmpfile}
	###	kill -[SIG_TRAPPED] $PID;;
}	


# -----------------------------------------------------------------------------
#
#   BEGINNING OF THE SCRIPT EXECUTION
#
# -----------------------------------------------------------------------------

### Trapping exiting code ###
trap 'f_error ERRROR 001 HUP' HUP 
trap 'f_error ERRROR 002 INT' INT 
trap 'f_error ERRROR 003 QUIT' QUIT
trap 'f_error ERRROR 015 TERM' TERM
# trap 'f_error EXITING 127 EXIT' EXIT 		## Generate too much garbage usually. 


# -----------------------------------------------------------------------------
#
#   LOADING OUR PARAMETER PARSER 
#
# -----------------------------------------------------------------------------	

### Validate if we have at least one parameter for our getops
if [[ $# -eq 0 ]]
then
	f_error ERROR 124 # ERROR 124 No command line arguments supplied
	usagemsg "${0}"
	exit 124
fi	

### Pass our parameter and do validation 
f_get_parameter "${@}"


# -----------------------------------------------------------------------------
#
#   THE REST OF THE ALGORYTHME GOES HERE  
#
# -----------------------------------------------------------------------------	








