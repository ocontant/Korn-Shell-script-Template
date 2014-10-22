#!/usr/bin/env python

"""
Description:

Last Update:
    By: Olivier Contant
    Email: olivier.contant@tritondigital.com
    Date: 2014-10-16
"""
__version__ = "1.0.1"

import sys
import logging                                  # https://docs.python.org/2/howto/logging.html
import time
import datetime
import os

###  How to add a module base on dependency
"""

try:
    import json
except ImportError:
    try:
        import simplejson as json
    except ImportError:
        if sys.version_info < (2, 6):
            print >> sys.stderr, 'simplejson (http://pypi.python.org/pypi/simplejson/) is required.'
            sys.exit(1)
"""


###
## Function declaration
###
def funcname(param1,param2,param3):
    #Type ''' to automatic insert documentation block#
    '''
    :param param1:
    :param param2:
    :param param3:
    :return:
    '''
    print "This is a function"


###
## Prepare loggin mechanism
###

### Create handler for stdout/stderr, error file, info file
def loggin_init(loglevel):
    numeric_level = getattr(logging, loglevel.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError('Invalid log level: %s' % loglevel)
    loginfo='/path/to/log/%s-info.log' % (print sys.argv[0])
    logerror='/path/to/log/%s-error.log' % (print sys.argv[0])
    #logdebug='/path/to/log/%s-debug.log'

## Main Program
if __name__ == "__main__":
    ### The main define if the script has been imported or is running directly.
    ### Allowing to use the function defined, as a module for another script to reuse later.

    ###
    ## Declare variables
    ###


    date = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
    logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s: %(message)s', datefmt='%m-%d-%Y %H:%M:%S')

    ###
    ## Your main code here.
    ###

