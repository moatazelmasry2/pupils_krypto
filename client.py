'''
Created on Apr 4, 2013

@author: elmasry
'''


import httplib
import sys
from sage.all import *

if len(sys.argv) != 2:
    print "Usage: %s <n>"%sys.argv[0]
    print "Outputs the prime factorization of n."
    sys.exit(1)

print factor(sage_eval(sys.argv[1]))


def runme():
    conn = httplib.HTTPConnection("localhost:8000")
    conn.request("GET", "/server.py")
    r1 = conn.getresponse()
    print r1.status, r1.reason
    