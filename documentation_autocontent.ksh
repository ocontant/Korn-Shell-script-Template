#!/usr/bin/ksh
################################################################
function usagemsg {
  print ""
  print "Program: autocontent"
  print ""
  print "This utility parses a list of scripts, extracts the comments"
  print "from within the script, and builds HTML snippets from the"
  print "extracted comments and source code."
  print "It uses a data file to specify the machine and full path"
  print "file name of the source file. Also specified in the data"
  print "file is the machine and directory location where the"
  print "HTML snippets will be placed."
  print ""
  print ""
  print "Usage: ${1##*/} {-d|-l|-f datafile} [-v] [-o] [-c|-u] [-?]"
  print ""
  print "    Where -d = Use ./AutoContent.dat as the data file"
  print "          -l = Use /usr/local/AutoContent/AutoContent.dat as the data file"
  print "          -f datafile = Specify the AutoContent Data File"
  print "          -v = Verbose Mode"
  print "          -o = Send all HTML output to STDOUT"
  print "          -c = Generate code document only"
  print "          -u = Generate usage document only"
  print "          -? = Display usage and help message"
  print ""
  print "Author: Dana French (dfrench@mtxia.com)"
  print ""
  print "\"AutoContent\" enabled"
  print ""
}
################################################################
#### 
#### Description:
#### 
#### This utility parses a list of scripts, extracts the comments
#### from within the script, and builds HTML snippets from the
#### extracted comments and source code.  The HTML snippet is saved 
#### in a location designated by the user under a file name comprised 
#### of the original file name suffix up to the first dot ".", followed 
#### by ".content.shtml".  The "shtml" extention is used because
#### the HTML snippet is intended to be used as part of a server-side
#### include document on a web server.
#### 
#### Operation of "AutoContent" is controlled by a data file that
#### contains information about the files to be processed.  Each
#### line of the data file represents a record of information and
#### is processed in sequence.  Each line of data should be 
#### formatted into a "source" and "destination" portion.  The 
#### source portion designates a file to be processed by 
#### "AutoContent" and the machine on which it resides.  The 
#### destination portion of the data line designates a machine 
#### and directory location to place the results of the processing.
#### 
#### The data file consists of a series of lines, one record
#### per line.  A record consists of several fields
#### specifying the source machine, full path file name,
#### followed by an optional field whose contents are
#### variable.  The next field specifies the destination machine
#### and should be separated from the previous set of "source" 
#### fields using a space, tab, pipe symbol or comma.  Following 
#### the destination machine name should be the full path
#### destination directory name.
#### 
#### Example data file records:
#### 
#### xyzmach:/usr/local/bin/script01.ksh:-?  webserver:/www/httpd/html/scripts
#### 
#### xyzmach:/usr/local/bin/script02.ksh|webserver:/www/httpd/html/scripts
#### 
#### xyzmach:/usr/local/bin/script03.ksh:-?,webserver:/www/httpd/html/scripts
#### 
#### In the above examples, the optional field following the
#### full path source file name contains the characters "-?".
#### This causes "AutoContent" to execute this script with a
#### "-?" option on the command line expecting to receive a
#### usage message.  The usage message is captured and added
#### to the documentation.
#### 
#### Assumptions:
#### 
#### It is assumed that any file defined in the data file with 
#### the "-?" optional field, is an executable file, recognizes
#### the "-?" option and generates a usage message if the script is
#### executed with that option.  Each file defined using 
#### the "-?" optional field WILL BE EXECUTED with the
#### "-?" option to generate the usage message.  If the script does not
#### recognize the "-?" option, THE SCRIPT WILL EXECUTE as though no
#### command line arguments were provided and perform whatever tasks
#### it does under that condition.  Be sure that any file referenced
#### by "autocontent" using the "-?" optional field, recognizes 
#### the "-?" option.
#### 
#### The "autocontent" script generates its list of files for which
#### it generates documentation from the files contained in 
#### the "/usr/local/AutoContent" directory.  Scripts should NOT be 
#### stored in this directory, only a symbolic link to the script 
#### should exist in "/usr/local/AutoContent".
#### 
#### Additional documentation may be generated if the comments within 
#### the script conform to the "autocontent" technique of imbedding 
#### comments in scripts.
#### 
#### Dependencies:
#### 
#### The list of scripts for the HTML snippet documents are generated, is
#### embedded within the "autocontent" script.  To change the list, the
#### "autocontent" script must be edited.
#### 
#### The "autocontent" script is a Korn Shell 93 script and must 
#### be executed using a Korn Shell 93 compliant script interpreter.
#### 
#### Products:
#### 
#### For each specified script, the "autocontent" script generates 
#### an HTML snippet file, that contains the usage message and any 
#### additional comments extracted from the script.  Also produced
#### is a separate HTML snippet file that contains the script itself
#### enclosed in HTML tags to preserve formatting.
#### 
#### Configured Usage:
#### 
#### This script requires no arguments and can be run from the command
#### line, scheduled, or executed from within another script.
#### This script does not perform any file transfers.  How the 
#### files generated by this script are utilized is beyond the scope
#### of this script.
#### 
#### Details:
#### 
################################################################
TRUE=1
FALSE=0
VERBOSE="${FALSE}"
STDOUT="${FALSE}"
USAGEDOC="${TRUE}"
CODEDOC="${TRUE}"
export DD_TMP="${DD_TMP:-/tmp}"
TMPFILE="/tmp/tmp${$}.tmp"

while getopts ":vdlf:ocu" OPTION
do
    case "${OPTION}" in
        'd') AUTOCONTENT="./AutoContent.dat";;
        'l') AUTOCONTENT="/usr/local/AutoContent/AutoContent.dat";;
        'f') AUTOCONTENT="${OPTARG}";;
        'o') STDOUT="${TRUE}";;
        'c') CODEDOC="${TRUE}"
             USAGEDOC="${FALSE}";;
        'u') USAGEDOC="${TRUE}"
             CODEDOC="${FALSE}";;
        'v') VERBOSE="${TRUE}";;
        '?') usagemsg "${0}" && exit 1 ;;
    esac
done
 
shift $(( ${OPTIND} - 1 ))
 
trap "usagemsg ${0}" EXIT
DATAFILE="${AUTOCONTENT:?ERROR: run \"${0} -?\" for help and usage}"
trap "-" EXIT

if [[ -f "${AUTOCONTENT}" ]]
then
   (( VERBOSE == TRUE )) && print -u2 "# Specified data file found"
   (( VERBOSE == TRUE )) && print -u2 "#     ${AUTOCONTENT}"
else
    print -u2 "# AutoContent data file does not exist"
    print -u2 "#     ${AUTOCONTENT}"
    exit 2
fi

################################################################
#### 
#### Data lines are read from a user designated file that contains
#### information that controls the operation of "AutoContent".
#### Each line of data should be formatted into a "source" and 
#### "destination" portion.  The source portion designates a file
#### to be processed by "AutoContent" and the machine on which it
#### resides.  The destination portion of the data line designates
#### a machine and directory location to place the results of the
#### processing.
#### 
#### Each line in the data file should be formatted as follows:
#### 
#### {source machine name}:{Full Path File Name}[:-?] 
#### {space, tab, comma or pipe} 
#### {destination machine name}:{Full Path Directory Name}
#### 
#### If the option flag "-?" is used at the end of a source
#### file name, the file will be treated as as script and
#### executed using the option flag as an argument.  This
#### assumes the option flag will cause the script to 
#### generate a usage message which will be captured and 
#### included in the generated documentation.
#### 
#### If used, the optional flag must be separated from the 
#### source file name using a colon (:).
#### 
################################################################

(( VERBOSE == TRUE )) && print -u2 "# Building scripts overview document"

while IFS="" read -r -- LINE
do
  if [[ "${LINE}" = *+([[:blank:]]|,|\|)* ]]
  then
    (( VERBOSE == TRUE )) && print -u2 "\n# Data line properly divided into SRC and DEST."
  else
    print -u2 "\n# ERROR: Data line improperly formatted."
    print -u2 "# ERROR: Unable to determine SRC and DEST areas."
    print -u2 "# ERROR: ${LINE}\n"
    continue
  fi

################################################################
#### 
#### The source portion of the data line is extracted from 
#### the data line by deleting the largest matching pattern from
#### the end of the line that matches anything up to the 
#### first space, tab, comma, or pipe symbol in the line.  The 
#### result contains the source machine name, the source file name,
#### and possibly an option flag.  The format of the result should 
#### have a colon (:) between the source machine name, the source
#### file name, and if present, the option flag.
#### 
#### If the result is formatted correctly, it is separated in to 
#### its components.  If the option flag is present, it is 
#### saved in a variable named "SRCFLAG".
#### 
################################################################

  SRCFLAG=""
  SRC="${LINE%%+([[:blank:]]|,|\|)*}"

  if [[ "${SRC}" = *:* &&
        "_${SRC##*:}" != '_' &&
        "_${SRC%%:*}" != '_' &&
        "_${SRC#*:}" != _-?* ]]
  then
    SRCMACH="${SRC%%:*}"
    SRCFILE="${SRC#*:}"
    if [[ "_${SRC##*:}" = _-?* ]]
    then
    (( VERBOSE == TRUE )) && print -u2 "# SRC portion of data line properly divided into MACH, FILE, and FLAG."
      SRCFILE="${SRCFILE%%:*}"
      SRCFLAG="${SRC##*:}"
    else
    (( VERBOSE == TRUE )) && print -u2 "# SRC portion of data line properly divided into MACH and FILE."
    fi
  else
    print -u2 "\n# ERROR: SRC portion of data line improperly formatted."
    print -u2 "# ERROR: Unable to determine MACH and FILE areas."
    print -u2 "# ERROR: ${SRC}\n"
    continue
  fi

################################################################
#### 
#### The destination portion of the data line is extracted from 
#### the data line by deleting the largest matching pattern from
#### the beginning of the line that matches anything up to the 
#### last space, tab, comma, or pipe symbol in the line.  The 
#### result contains both the destination machine name and the 
#### destination directory.  The format of the result should have 
#### a colon (:) between the destination machine name and the 
#### destination directory.
#### 
#### If the result is formatted correctly, it is separated in to 
#### its components. 
#### 
################################################################

  DEST="${LINE##*+([[:blank:]]|,|\|)}"

  if [[ "${DEST}" = *:* &&
        "_${DEST##*:}" != '_' &&
        "_${DEST%:*}" != '_' ]]
  then
    (( VERBOSE == TRUE )) && print -u2 "# DEST portion of data line properly divided into MACH and DIR."
    DESTMACH="${DEST%%:*}"
    DESTDIR="${DEST#*:}"
  else
    print -u2 "\n# ERROR: DEST portion of data line improperly formatted."
    print -u2 "# ERROR: Unable to determine MACH and DIR areas."
    print -u2 "# ERROR: ${DEST}\n"
    continue
  fi

#
#   SRC="${LINE%%+([[:blank:]]|,|\|)*}"
#   DEST="${LINE##*+([[:blank:]]|,|\|)}"
#   SRCMACH="${SRC%%:*}"
#   SRCFILE="${SRC#*:}"
#   SRCFILE="${SRCFILE%%:*}"
#   SRCFLAG="${SRC##*:}"
#   [[ "_${SRCFILE}" = "_${SRCFLAG}" ]] && SRCFLAG=""
#   DESTMACH="${DEST%%:*}"
#   DESTDIR="${DEST#*:}"
#
  
################################################################
#### 
#### Define the command to use to copy the source file from its
#### original location into a temporary file.  Assume the source
#### file exists on a remote machine and define the copy command
#### as a remote copy, followed by the source machine name, 
#### followed by a colon.  Then test to see if the source machine
#### name is the same as the local machine name or defined as 
#### "localhost".  If so, reset the copy command to be a simple
#### copy followed by a space.
#### 
#### After defining the copy command, perform the copy.
#### 
################################################################
  CMD_CP="rcp ${SRCMACH}:"
  [[ "${SRCMACH}" = *$( uname -n )* ]] && CMD_CP="cp "
  [[ "${SRCMACH}" = localhost ]] && CMD_CP="cp "
  rm -f "${TMPFILE}"
  ${CMD_CP}${SRCFILE} ${TMPFILE}

  FILENAME="${SRCFILE##*/}"

################################################################
#### 
#### For each script, an HTML snippet file is created to contain
#### the usage message and any additional "autocontent" compliant 
#### comments that can be extracted from the script.  This file is
#### named using the file name suffix of the original script up to
#### but not including the first dot ".", followed by "doc.content.shtml".
#### 
#### The ".shtml" is used so the document may additionally use
#### server-side includes.
#### 
################################################################
  if (( USAGEDOC == TRUE ))
  then

    (( VERBOSE == TRUE )) && print -u2 "# Building ${FILENAME} usage document"

    OUTFILE="${DD_TMP}/${FILENAME%%.*}doc.content.shtml"
    (( STDOUT == TRUE )) && OUTFILE='&1'

    eval "exec 3>${OUTFILE}"
  
    print -u3 ""
  
################################################################
#### 
#### Each Script is executed with the "-?" option to generate the
#### usage message associated with the script.  This usage message
#### is saved in the documentation for the script.
#### 
#### Any "<" or ">" symbols generated by the usage message or extracted
#### from the script in the additional comments, are converted to
#### HTML recognizable codes that will be interpreted by the web
#### browser when the page is displayed.
#### 
################################################################
  
    if [[ "_${SRCFLAG}" != "_" ]]
    then
      (( VERBOSE == TRUE )) && print -u2 "# Executing script to generate usage message"
        print -u3 "
"
        chmod 755 "${TMPFILE}"
        /usr/bin/ksh93 "${TMPFILE}" -? |
          sed -e "s//\>/g;s|${TMPFILE##*/}|${SRCFILE##*/}|g" |
          grep -v "ERROR" >&3
  
        print -u3 "
"
    fi

    (( VERBOSE == TRUE )) && print -u2 "# Generating additional documentation for \"${FILENAME}\""
    print -u3 "
"
  
################################################################
#### 
#### Additional comments may be extracted from the scripts if the
#### comments conform to the "autocontent" technique of commenting
#### scripts.  This technique extracts only those comments embedded
#### within a script which begin with four hash marks followd by 
#### a single space (#### ).  This pattern must also occur at the 
#### beginning of the line.  Any comments which begin with this 
#### pattern are extracted and reformatted as an HTML paragraph.
#### 
#### Multiple paragraphs may be designated within the script by
#### using the (#### ) pattern with nothing following.  This will
#### be interpreted by the "autocontent" generated to mean "insert
#### end of paragraph tag followed by a begin paragraph tag".
#### 
#### Any extracted comment line which ends with a colon ":" will 
#### be enclosed in HTML STRONG tags to make the text bold when 
#### displayed in a browser.
#### 
#### If "autocontent" generates multiple "End Paragraph - 
#### Begin paragraph" pairs, they will be collapsed into a single pair.
#### 
################################################################
  
    grep "^#### " "${TMPFILE}" |
      sed -e 's/^#### //g;s/^$/<\/P>
/g' |
      uniq |
      sed -e '1,1 s/<\/P>

/

/g;$,$ s/<\/P>

/<\/P>/g' |
      sed -e 's/.*:$/&<\/STRONG>/g' >&3
# 
# A server-side-include directive that displays the date when
# the document was generated is added to the end of each document.
# 
    print -u3 "

"
    print -u3 "This file last modified (none)

"

    print -u3 ""
  
    exec 3>&-
  
  fi    # (( USAGEDOC == TRUE ))

################################################################
#### 
#### Also for each script, an HTML snippet file is created to contain
#### the script source code.  This file is
#### named using the file name suffix of the original script up to
#### but not including the first dot ".", followed by ".content.shtml".
#### 
#### The ".shtml" is used so the document may additionally use
#### server-side includes.
#### 
################################################################
  
  if (( CODEDOC == TRUE ))
  then

    (( VERBOSE == TRUE )) && print -u2 "# Building ${FILENAME} code document"

    OUTFILE="${DD_TMP}/${FILENAME%%.*}.content.shtml"
    (( STDOUT == TRUE )) && OUTFILE='&1'

    eval "exec 3>${OUTFILE}"
  
    print -u3 ""
    print -u3 "
Script Source Code for \"${FILENAME}\"

"
    print -u3 "
This document contains the source code for the"
    print -u3 "script \"${FILENAME}\"."
    print -u3 "

"
  
################################################################
#### 
#### Any "<" or ">" symbols generated by the usage message or extracted
#### from the script in the additional comments, are converted to
#### HTML recognizable codes that will be interpreted by the web
#### browser when the page is displayed.
#### 
################################################################
  
    cat "${TMPFILE}" |
      sed -e "s//\>/g;s/\\\&/\\\\\&/g;" >&3
  
    print -u3 "
"
  
################################################################
#### 
#### A server-side-include directive that displays the date when
#### the document was generated is added to the end of each document.
#### 
################################################################
  
    print -u3 "
"
    print -u3 "This file last modified (none)

"

    print -u3 ""
  
    exec 3>&-
  
  fi    # (( CODEDOC == TRUE ))

  rm -f "${TMPFILE}"

  if (( STDOUT == FALSE ))
  then
    CMD_CP="rcp"
    DESTNAME="${DESTMACH}:${DESTDIR}"
    if [[ "${SRCMACH}" = *$( uname -n )* ]]
    then
      DESTNAME="${DESTDIR}"
    fi

    if [[ "${DESTMACH}" = *$( uname -n )* ]]
    then
      DESTNAME="${DESTDIR}"
    fi

    if [[ "${SRCMACH}" = *$( uname -n )* && "${DESTMACH}" = *$( uname -n )* ]]
    then
      CMD_CP="cp"
    fi

    if (( USAGEDOC == TRUE ))
    then
      chmod 644 "${DD_TMP}/${FILENAME%%.*}doc.content.shtml"
      (( VERBOSE == TRUE )) && print -u2 "# Copying usage document file to destination"
      (( VERBOSE == TRUE )) && print -u2 "# Destination: ${DESTNAME}"
      ${CMD_CP} "${DD_TMP}/${FILENAME%%.*}doc.content.shtml" "${DESTNAME}"
      rm -f "${DD_TMP}/${FILENAME%%.*}doc.content.shtml"
    fi    # (( USAGEDOC == TRUE ))

    if (( CODEDOC == TRUE ))
    then
      chmod 644 "${DD_TMP}/${FILENAME%%.*}.content.shtml"
      (( VERBOSE == TRUE )) && print -u2 "# Copying code document file to destination"
      (( VERBOSE == TRUE )) && print -u2 "# Destination: ${DESTNAME}"
      ${CMD_CP} "${DD_TMP}/${FILENAME%%.*}.content.shtml" "${DESTNAME}"
      rm -f "${DD_TMP}/${FILENAME%%.*}.content.shtml"
    fi    # (( CODEDOC == TRUE ))

  fi

done < "${AUTOCONTENT}"

################################################################
#### 
#### Environment Variables:
#### 
#### DD_TMP = Directory for storage of HTML snippet files
#### 
################################################################