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
import logging                                  #https://docs.python.org/2/howto/logging.html#logging-to-a-file
import time
import datetime
import os
from fussy import cronlock

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


## Main Program
if __name__ == "__main__":
    ### The main define if the script has been imported or is running directly.
    ### Allowing to use the function defined, as a module for another script to reuse later.

    ###
    ## Declare variables
    ###
    date = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')

    lockfile='/path/to/lockfile'    #Default to /var/run/file.pid ** Require the script to run as root **
    lock.set_timeout(120)           #fussy.cronlock.Timeout





    ###
    ## Your main code here.
    ###
    lock = cronlock.Lock(lockfile)
    with lock:
        #Your main code here.