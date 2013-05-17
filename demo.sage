# -*- coding: utf-8 -*- 
'''
Created on Apr 26, 2013

@author: elmasry
'''

def execute():
    global N,e,d, username
    attach "moneypenny.sage"
    init()
    file1 = "imnothere.txt"
    global secretfile
    
    user1 = "bond"
    user2 = "bram"
    
    username = user1
    
    #print "Erzeuge Schlüssel..."
    p = nextprime(2^4)
    q = nextprime(2^5);
    if p ==q: print "p=q ist verboten!"
    else: print "OK. (p<>q)"
    N = p*q;
    L = (p-1)*(q-1);
    p = q = None
    
    while True:
        e = random(3,L-2)
        #print "Teste: e=" + str(e)
        if GCD(e,L) == 1: break
    #print "Gefunden: e=" + str(e)
    d = 1/e % L
    L = None
    #checkmail()
    #y = readmail();
    secret = [N,d];
    public = [N,e];
    print "Schlüssel erzeugt."
    
    
    print "Übersetze Nachricht."
    x = text2num("Hi ich heiße niemand")
    if x >= N: print "Nachricht zu lang!"
    
    print "Verschlüsseln..."
    y = x.powermod(e, N)
    clearInbox()
    mailto( "moneypenny@mi6.gov.uk", "Hier mo", N, e, y)
    
    username = user2
    getkey(user1)
    msg = "blablablabla"
    x = text2num(msg)
    y = x.powermod(e, N)
    mailto(user1 + "@bit.uni-bonn.de", "vom Bram", N, e, y)
    
    
    username = user1
    checkmail()
    
    y = readmail(-1)
    getkey(msgN,msge)
    
    print "Entschlüsseln..."
    z = y.powermod(d, N)
    print "Übersetze Zahl."
    print num2text(z)
    