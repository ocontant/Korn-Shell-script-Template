#!/usr/bin/ksh
################################################################
# Script to automate SCOAD activity

# Copyright (C) 2013 Olivier Contant - All Rights Reserved
# Permission to copy and modify is granted
#
# https://github.com/ocontant 
#
# Last revised 2015/05/04
#
################################################################
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
#### with a description for each.
#### 
#### Configured Usage:
#### 
#### Describe how your shell function should be used.
#### 
#### 
################################################################


  typeset version="1.0"						# Increment this number with every new version
  typeset date=`date "+%y-%m-%d"`			# Standard date: 2015-04-27
  typeset scriptname=`basename $0`			# The file name of the script being called
  typeset TRUE="1"							# Logical Bool aliases True
  typeset FALSE="0"							# Logical Bool aliases False
  typeset verbose="${false}"				# Define a level of verbosity for your script: Use with this syntaxe:  (( verbose == true )) && echo "verbose text"  OR [[ $verbose == true ]] && echo "verbose text"
  typeset veryverb="${false}"				# Define a level of verbosity for your script: Use with this syntaxe:  (( veryverb == true )) && echo "very verbose text" OR [[ $veryverb == true ]] && echo "very verbose text"
  typeset debug="${false}"					# Display debug informations:  Use with this syntaxe:  (( debug == true )) && echo "debug text" OR [[ $debug == true ]] && echo "debug text"
  typeset logfile=""						# to define the location and filename of where we want to write the log of the execution of this script
  typeset errorfile=""						# To define the location and filename of where we want to write the error log of the execution of this script
  typeset PID=$$							# The main process ID instance of our script
  typeset rc=""  								# Return Command executing code handling
  typeset tmpfile="${TMPDIR:-/tmp}/prog.$$" # temp filename will be /tmp/prog.$$.X or variable name $tmpfile.X
  
  
  
 ### If we need logfile
 # exec >> $logfile
 
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
#   Message - Print meaningful error messages
#
# -----------------------------------------------------------------------------
function f_error #$1=errortype&errornum&message
{
    # [[ ! -z "$debug" ]] && set -x

    ### Feel free to add your own custom error message 
    ### Don't forget to add a trap in next section for your custom error number

     
    dtg=`date +%D\ %H:%M:%S`
    if [[ ! "$1" = "" ]];then
        errortype=$1; shift
        errornum=$1; shift
	errormsg=$1; shift
    fi

    echo ""
    f_print_separator
    echo ""
    echo "$errortype: $errornum"
    echo ""
    f_print_separator

    ert="$dtg: $scriptname: $errortype"
    case $errornum in
        000) erm="${ert}: Normal Termination ${errormsg}";;
        001) erm="${ert}: Terminated by signal HUP; ${errormsg}";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$erm"
			kill -HUP $PID;;
	002) erm="${ert}: Terminated by signal INT;${errormsg}";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$erm"
			kill -INT $PID;;
	003) erm="${ert}: Terminated by signal QUIT; ${errormsg}";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$erm"
			kill -QUIT $PID;;
	015) erm="${ert}: Terminated by signal TERM; ${errormsg}";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$erm"
			kill -TERM $PID;;
        124) erm="${ert}: No Parameter found; ${errormsg}";;
        125) erm="${ert}: Invalid command line flag. ${errormsg}";;
	126) erm="${ert}: File or Directory $errormsg doesn't exist!"; rc=1;;
	127) erm="${ert}: Script exiting!";
			[[ ! -z tmpfile ]] && rm -f ${tmpfile}
			echo "$erm"
			kill -TERM $PID;;
        *) erm="${ert}: Unallocated error ............$errornum; ${errormsg}";;
    esac
    echo ""
    echo "$erm"
    echo ""
    f_print_separator
    echo ""
    echo ""

	
	######## Example of usage of error function
	### 1. This example should be included in all script at the very end to show a normal run exit message.
	###    f_error INFO 000 (at end of script after normal execution
	###
	### 2. The following example is for ERROR type that doesn't exit in the f_error itself.
	###	   f_error ERROR 124
	###    usage
	###  	 exit 124
	###
	### 3. The following examples are for the ERROR type that exit in the f_error itself
	###    trap 'f_error ERROR 001' HUP
	###	   trap 'f_error ERROR 002' INT
	###	   trap 'f_error ERROR 003' QUIT
	###    trap 'f_error ERROR 015' TERM
	###
	### Make sure when trapping exiting signal to kill the process also or the process will hang
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
# trap 'f_error EXITING 127 EXIT' EXIT 		## Generate too much garbage usually and loop. 


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


# -----------------------------------------------------------------------------
#
#   If everything else ran successfully 
#
# -----------------------------------------------------------------------------	
f_error INFO 000 "${scriptname} executed succesfully"





