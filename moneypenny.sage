# -*- coding: utf-8 -*- 
#from sage.crypto.util import ascii_to_bin
from sage.all import *
import math
import httplib
import uuid
import getpass
import signal
import sys, traceback

    
minlbN=666;  minN = 2^minlbN
maxlbN=3000; maxN= 2^maxlbN
xcounter = ycounter = 0
username = getpass.getuser()
folderMoneypenny = "../"
#ip = "cosec-12"
ip = "cosec-12"
port = 80
set_random_seed(31)

keyringdir = folderMoneypenny + "keyring\\"
#secretfile = folderMoneypenny + "imnothere.txt"
secretfile = "imnothere.txt"
antworten = []
N = e = d = None
msgN = msge = None
    
def init():
    load "antwortenhandler.sage"
    a = AntwortenHandler()
    global antworten
    antworten = a.antwortentext
    antworten = [s.encode("utf-8") for s in antworten]
    antworten = map(text2num, antworten)    
    print "init program"

def handler(signum, frame):
    raise Exception("end of time")

def loop_forever():
    import time
    print "inside"
    #while True:
    for i in range(20):
        print "sec: " + str(i)
        time.sleep(1)
    return 1;

def timeout(func, args=(), kwargs={}, timeout_duration=10):
    @fork(timeout=timeout_duration, verbose=True)
    def my_new_func():
        return func(*args, **kwargs)
    return my_new_func()
'''
#TODO make this function blocking
def timeout(func, args=(), kwargs={}, timeout_duration=10):
    """
    The timeout function runs a given function for a certain timeout before raising an excpetion
    the implementation is taken from: 
    http://stackoverflow.com/questions/492519/timeout-on-a-python-function-call
    """

    # Register the signal function handler
    signal.signal(signal.SIGALRM, handler)

    # Define a timeout for your function
    signal.alarm(timeout_duration)
    
    result = None
    returned = False
    try:
        print "tying to crack the key"
        result =  func(*args, **kwargs)
        #the function returned fine. stop the alarm
        signal.alarm(0)
        print "landed in success"
        returned = True
    except Exception:
        signal.alarm(0)
        print "landed in failure"
        returned = True
        
    #while (returned == False):
    #    pass
    
    print "out of the infinit loop"
    return result
'''    
    
def text2num(text):
    """
    text2num(text)
    Codiert den Text zu einer Zahl
    """
    return sum( [256^(i)*ord(c) for i,c in enumerate(text)] )

def num2text(x):
    """
    num2text(x)
    Decodiert aus x wieder den Text - passend zu text2num
    """
    list = x.digits(base=256)
    return ''.join([chr(i) for i in list])

def crackKey(N ,e):
    """
    crackKey(N, e)
    Testet den Schlüssel mit der Funktion specialfactor(). Sollte stets
    mit der Option traperror und einem Timeout aufgerufen werden, da 
    ifactor ansonsten recht lange brauchen kann. :-)
    """
    
    #TODO comment specialfactor until some stuff are cleared
    #Nf = specialfactor(N)
    #if Nf <> None: 
    #    print "special factor cracked the key"
    #    #return "N = " + str(Nf)
    #    return Nf
    #Nf = factor(N);
    #return "N =" + str(Nf)
    Nf = factor(N)
    return Nf


def fetch(ip,port, request):
    
    #TODO at the moment, port parameter produces an error under sage
    #return httplib.HTTPConnection(ip,port).request("GET", request).getresponse()
    conn = httplib.HTTPConnection(ip)
    #print "ip=" + ip
    #print "request =" + request
    conn.request("GET", request)
    return conn.getresponse().read()
 
def checkmail():
    """
    checkmail()
    Das Programm liest die Inbox des Anwenders aus und gibt sie wieder.
    """
    result = readinbox()
    #Es folgt die Wiedergabe
    
    if isinstance(result,list) and len(result) > 0:
        for i,val in enumerate(result):
            print "Nachricht Nummer: " + str(i) + " Absender: " + val["absender"] + " Betreff: " + val["absender"] + "\n"
            #Nun werden N, e, die verschlüsselte Nachricht und der Absender der
            #nächsten Nachricht eingelesen und unter "text" abgespeichert. (Dadurch
            #werden N, e und die Nachricht verworfen, sie interessieren uns hier nicht.)
            
    else: print "Keine Email vorhanden.\n"
    

def readinbox():
    """
    readinbox()
    Liest die Inbox ein und speichert sie in den Arrays absenderarray,
    betreffarray, Narray, earray und textarray ab. Ausserdem wird der Index
    index gesetzt. 
    Ergebnis wird in GLOBALEN Variablen
    index, absenderarray, betreffarray, Narray, earray, textarray
    zurückgegeben.
    """
    fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=getmail&username=" + username + \
                        "@bit.uni-bonn.de")
    #Die Rückgabe des PHP-Servers teilen wir an den Newlines in einzelne
    #Strings und trennen so die einzelnen Nachrichten sowie den Header ab.
    fetchparts = fetchresult.split("\n");
         
    result = []
    for i in fetchparts:
        if i =="\r" or i == "":
            continue
        #TODO: eigtl, wannimmer nicht Zahl
        if "Kann nicht" in i:
            break
        ganz = num2text(Integer(i))
        parts = ganz.split("|")
        
        msg = {"absender":parts[2], \
               "betreff": parts[4], \
               "N": Integer(parts[6]),\
               "e":Integer(parts[8])}
        if len(parts) > 10:
            msg["text"] = parts[10] 
        
        result.append(msg)
    return result


#*************************************************************************
# savekey()
# Das Programm speichert den Key im secretfile ab, damit er später
# rekonstruiert werden kann.
#*************************************************************************
def savekey(N,e,d):
    #* Wenn eine zufällige Zahl (x) nach ver- und entschlüsseln
    #* (powermod(x,d*e,N)) nicht gleich sich selbst ist, dann ist das
    #* Schlüsselpaar kaputt
    x = random(2,N-1)
    if x.powermod(d*e,N) <> x:
        print "Schlüsselpaar kaputt :-("
        return false
    #Mit der Variable foundit wird verhindert, dass zweimal derselbe Schlüssel abgespeichert wird.
    foundit = false
    
    with open(secretfile, 'a+') as file:
        #Falls das secretfile geöffnet werden konnte, dann schauen wir nach, ob
        #der Schlüssel schon drinsteht
        for line in file:
            splits = line.split("-");
            if len(splits) >= 3:
                olde = splits[0];oldN = splits[1];oldd = splits[2]
                #Das tun wir solange, bis das Ende der Liste oder eben exakt der
                #Schlüssel gefunden wird.
                if olde == e and oldN == N:
                    foundit = TRUE;break
        #Wird der Schlüssel gefunden, so liegt er ja schon gespeichert vor und
        #muss nicht mehr neu abgelegt werden. Andernfalls wird er nun der Datei angehängt.
        if foundit:
             
            return False
        file.write(str(e) + "-" + str(N) + "-" + str(d) + "\n");
        return True
        #no need to close the file.'with' python keyword closes it automatically

#*************************************************************************
# retrievesecretkey(lostN, loste)
# Sucht im secretfile nach einem Schlüssel mit N=lostN und e=loste und
# speichert ihn (mitsamt d) unter N, e und d ab.
#*************************************************************************
def retrievesecretkey(lostN, loste):
    # Öffne die Datei und lese die erste Zeile ein. Solange sich N von lostN
    # bzw. e von loste unterscheiden, fahre damit fort. Wenn dann nach dem
    # Durchlauf e noch immer von loste oder N von lostN verschieden sind, so
    # wurde der Schlüssel nicht gefunden. Andernfalls kann man ihn abspeichern.
    
    #if not os.path.exists(secretfile):
    #    print "Key is not auf diesem PC gespeichert"
    #    return
    
    with open(secretfile, 'r+') as file:
        oldN = olde = oldd = None
        for line in file:
            splits = line.split("-");
            if len(splits) >= 3:
                olde = Integer(splits[0]);oldN = Integer(splits[1]);oldd = Integer(splits[2])
                if oldN == lostN and olde == loste:
                    break
        
        if olde<>loste or oldN<>lostN or oldN == None or olde == None or oldd == None:
          raise IOError, "Schlüsselpaar nicht wiedergefunden. :-("
        global N,e,d
        N = oldN
        e = olde
        d = oldd
        print   "Der geheime Schlüssel wurde wiederhergestellt.\n" +\
                "ACHTUNG: Die vorherigen Werte von N, e und d wurden" +\
                " somit überschrieben.\n"
    
#*************************************************************************
#checkkey(userid, e = 0)
#Importiert aus dem keyringdir eine Datei userid.".mu" und liest aus ihr
#den öffentlichen Schlüssel aus.
#*************************************************************************/
def checkkey(userid):
    #Frag den Server nach dem neuesten Schlüssel des angegebenen Users.
    fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=keydownload&username=" + str(userid) )

    #Die Rückgabe des PHP-Servers teilen wir an den Newlines in einzelne
    #Strings und trennen so die einzelnen Nachrichten sowie den Header ab.
    fetchparts = fetchresult.split("\n")

    indexN = "Not yet found"
    for i in range(0,len(fetchparts) -1):
        if "N := hold" in fetchparts[i]:
            indexN = i
        elif "e := hold" in fetchparts[i]:
            indexe = i
    if indexN == "Not yet found":
      return None
  
    parts = fetchparts[indexN].split("(")
    parts = parts[1].split(")")
    N = Integer(parts[0])

    parts = fetchparts[indexe].split("(")
    parts = parts[1].split(")")
    e = Integer(parts[0])
    print "N=" + str(N) + ", and e=" + str(e)
    return [N,e]


#*************************************************************************
#getkey(userid, e = 0)
#Importiert aus dem keyringdir eine Datei userid.".mu" und liest aus ihr
#den öffentlichen Schlüssel aus.
#*************************************************************************
def getkey(userid, eteil = 0):
    if eteil <> 0:
      retrievesecretkey(userid, eteil)
      return
    #Frag den Server nach dem neuesten Schlüssel des angegebenen Users.
    res = checkkey(userid)

    if res == None:
      print "Fehler: Der Schlüssel konnte auf dem Server nicht gefunden werden."
      return
  
    global N,e,d
    N,e = res[0], res[1]
    d = None
  
    print "N und e des Users " + userid + " wurden erfolgreich heruntergeladen.\n" +\
        "ACHTUNG: Die vorherigen Werte von N und e wurden somit überschrieben und d wurde gelöscht\n"

#mpanswer()
#Sucht sich eine zufällige Antwort aus der Liste heraus und
#verschlüsselt sie mit dem jeweiligen Schlüssel des Anwenders.
def mpanswer():
    #In der Liste antworten sind die bereits in Zahlen codierten Antworten
    #gespeichert. Hier wird zunächst eine zufällige Antwort ausgesucht.
    global antworten, e, N
    randNum = random(0,len(antworten) - 1)
    number = antworten[randNum]
    #Nun wird die Zufallsantwort verschlüsselt und zurückgegeben.
    number = number.powermod(e, N)
    return number

#*************************************************************************
#specialfactor(N)
#Versucht mit gezielten Ansätzen eine Faktorisierung von N und gibt 
#diese - wenn erfolgreich - zurück. Detailfragen bitte an Michael Nüsken. :-)
#*************************************************************************
def specialfactor( N ):
  #
  #  Assuming N = (2^i+x)(2^j+y) for sufficiently
  #  small x and y, i>j, compute the factors.
  #  (c) 2006, Michael Nüsken, Bonn
  N2 = N.digits(base=2)
  n = len(N2)-1 # i+j
  if n < 50:
    #N is small, ask standard factor
    print "solved: N is small"
    return(factor(N))
  if N2[0] == 0:
    #N is even -> do not try to factor
    print "solved: N is even"
    return Factorization([(2,1),(N/2,1)])
  #if N2[n] <> 0:
    #x,y are so large or i,j so different that
    #they produce a 2^(i+j-1) digit
    #TODO not sure this solution makes sense. This condition is unclear
    #print "not solved, x,y are large"
    #return None
  for k in range(n-1, n/2, -1):
    if N2[k] == 1: break
  #print Typeset,"Found k=".k
  if N2[k] == 0:
    #N cannot be of the special form.
    return None
  #Try the case i=j:
  if n % 2 == 0:
    i = n/2
    j = n/2
    #converts a dyadic representation of a number to basis 2 back to the original number
    s = ZZ(N2[i:k], 2)
    p = ZZ( N2[0:i-1], 2 )
    d = sqrt(s^2-4*p);
    if isinstance(d,Integer): 
      ##S := {[x = (s+d)/2, y = (s-d)/2]};
      ##print(Typeset,"Candidate with j=".j = S );
      Nf = Factorization([(2^i+(s+d)/2,1),(2^j+(s-d)/2,1)])
      ##print(Typeset,"...made it to "=Nf);
      #TODO expr?
      if N == Nf.value():
        print "solved: N has been cracked 1"
        return Nf
  #Try possible values for j.
  for j in range((n-1) / 2, 0, -1):
    i = n-j
    if N2[j] <> 1: continue #Must have a 1 at bit[j].
    for l in range(j-1, -1, -1):
      if N2[l] == 1: break
    #print(Typeset,"For j=".j." found l=".l.", which should match xi+eta=".(2*k-n)." or xi+eta+1");
    if l > 2 * k - n + 1:
      #We must have zero bits down to bit xi+eta+2 which is bounded by 2k-n+2.
      continue
    #We must fulfill one of the following three conditions:
    ##print(Typeset, k=i+eta+1, k=j+xi+1, n=i+j, l=xi+eta+oneorzero, "ie.", l=2*k-n-2 );
    ##print(Typeset, k=i+eta, k>j+xi, n=i+j, l=xi+eta+oneorzero, "ie.", l=xi+k-i+oneorzero );
    ##print(Typeset, k>i+eta, k=j+xi, n=i+j, l=xi+eta+oneorzero, "ie.", l=eta+k-j+onorzero );
    # Yet, it does not seem worth the time checking them...         
    #solve
    s = ZZ( N2[j:k], 2 )
    p = ZZ( N2[0:l], 2 )
    ##/*
    ##S := solve( {s=x+y*2^(i-j),p=x*y}, [x,y] );
    ##print(Typeset, "Control with j=".j );
    ##print({s=x+y*2^(i-j),p=x*y} );
    ##print(Typeset, S );
    ##*/
    d = math.sqrt(s^2-2^(i-j+2)*p)
    #print(Typeset,"Candidate with j=".j = d );
    if not isinstance(d,int): continue
    #S = {[x = (s+d)/2, y = (s-d)*2^(j-i-1)],[x = (s-d)/2, y = (s+d)*2^(j-i-1)]}
    S = [ ((s+d)/2, (s-d)*2^(j-i-1)) ,( (s-d)/2, (s+d)*2^(j-i-1) ) ]
    #print(Typeset,"Candidate with j=".j = S );
    if len(S) > 0:
      for s in S:
          #TODO the expression is not clear
          #TODO at this step a factored expression should be created
          Nf = (subs( [1,2^i+s[0],1,2^j+s[1],1], s ))
          if not isinstance(Nf,sage.structure.factorization_integer.IntegerFactorization):
              continue
          #TODO doesn't make sense to factor a factored expression
          #Nf = Factored(Nf)
          #print(Typeset,"...made it to "=Nf);
          if N == Nf.value():
              print "solved: N has been cracked 2"
              return Nf
  return None

#************************************************************************/


#*************************************************************************
#clearInbox()
#Löscht die Inbox-Datei.
#*************************************************************************
def clearInbox():
    fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=clearinbox&username=" + username + "@bit.uni-bonn.de")
    print "Dein Postfach wurde gelöscht.\n"

def readmail(number=0):
    result = readinbox()
    numMsgs = len(result)
    if numMsgs == 0:
        print "Keine Email vorhanden.\n"
        return
    #Hiermit verarbeite ich die Sonderfälle, dass die number-letzte Nachricht
    #bzw. die aktuelle Nachricht verlangt wird.
    if number < 0:
       number = numMsgs + number
    
    #number>index bedeutet, dass eine Nachricht abgefragt wird, die gar nicht
    #vorhanden ist. Dann wird standardmäßig die neueste Nachricht gelesen.
    if number > numMsgs - 1:
        print "Keine Nachricht mit diesem Index (" + number + ") vorhanden.\n"
        print "Es wird die neueste Nachricht wiedergegeben!\n"
        number = numMsgs - 1
      #Hiermit wird die Nachricht dann ausgelesen und gespeichert.
    global msgN,msge
    
    msgabsender = result[number]["absender"]
    msgbetreff = result[number]["betreff"]
    msgN = result[number]["N"]
    msge = result[number]["e"]
    msgtext = None
    if "text" in result[number]:
        msgtext = result[number]["text"]
    
    #Das ist recht selbsterklärend: Ist der Typ des Nachrichtentextes
    #DOM_NULL oder ist die Nachricht leer, so sag das auch.
    if msgtext is None:
        print "Keine Nachricht vorhanden oder leere Email.\n"
    elif msgtext == '':
       print "Die Nachricht ist leer!\n"
    elif isinstance(msgtext,str):
      print "*****************************************************************\n" +\
            "********************* WARNUNG ***********************************\n" +\
            "*****************************************************************\n" +\
            "********************** KLARTEXT-NACHRICHT: **********************\n" +\
            "*****************************************************************\n" +\
            " \n"
      print msgtext
      print "Absender" + msgabsender + "\n"
      print "Betreff: " + msgbetreff + "\n"
   
    print "\nACHTUNG: Die Variablen msgN und msge wurden soeben mit Werten belegt.\n"
    print "Du kannst nun mit dem Befehl  getkey(msgN,msge)  den Schlüssel laden,\n" 
    print "den Du zum Entschlüsseln der Nachricht benötigst.\n"
    return Integer(msgtext)

def mailto_user(adresse, subject, N, e, nachricht):
    global username
    if checkkey(adresse) == False:
        #TODO correct this funny error message 
        print "Mailerdämon: Nachricht wird NICHT zugestellt. Empfänger muss ein Account sein\
            , der einen öffentlichen Schlüßel besitzt."
        return False
    
    print"Mailerdämon: Nachricht wird zugestellt. Bitte hab einen Moment Geduld...\n";
    #define username
    msgcontent = "begin_of_message|" + \
                "absender|" + username + "|" + \
                "betreff|" + subject + "|" +\
                "N|" + str(N) + "|" + \
                "e|" + str(e) + "|" + \
                "text|" + str(nachricht)
    msgcontent = text2num(msgcontent)
    fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=msgsent&username=" + adresse +\
                         "&content=" + str(msgcontent) )
    print "Mailerdämon: Die Nachricht wurde erfolgreich an " + adresse + " verschickt."
    
def mailto_moneypenny(adresse, subject, N, e, nachricht):
    testresult = None
    if N < minN: 
        print "N ist zu klein. Versuche es mit einem größeren Wert. (N sollte mindestens 2^" + str(minlbN) + " sein.)"
        return None
    elif N > maxN: 
        print "N ist zu gross. Versuche es mit einem kleineren Wert. (N sollte kleiner als 2^" + str(maxlbN) + " sein."
        return None
    testresult = timeout(crackKey, ([N,e]), timeout_duration=5)
    #testresult = timeout(loop_forever, (), timeout_duration=10)
    
    #See if this function takes too long to execute. if this is the case, then accept and save the key, 
    #else refuse it and name the factors of N
    global ip,port, username, d
    
    
    if testresult == None or "NO DATA" in testresult: 
        nachricht = mpanswer()
        #Der Schlüssel wird zweimal abgespeichert: Die erste Datei enthält stets
        #den aktuellen Schlüssel, die zweite wird nicht überschrieben und ist als Archivkopie gedacht.
        fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=keyupload&N=" + str(N) + \
                            "&e=" + str(e) + "&username=" + username)
        print savekey(N,e,d)
        
        print "\nQ sagt: Der geheime Schlüssel wurde in Sicherheit gebracht, 007. \nIn Deiner Mailbox solltest Du eine Antwort von Moneypenny vorfinden.\n" + \
         "Du kannst Dein Postfach mit checkmail() überprüfen.\n"
    else: 
        print "Moneypenny sagt: Du bist nicht James Bond. Der würde keinen so einfachen Schlüssel nehmen:\n"
        if isinstance(testresult, Factorization):
            print str(testresult.value()) + ".\n\n Schau Dir die Binärdarstellung von N an: \n"
            print N.binary()
            
            p = testresult[0][0]^testresult[0][1]
            
            print "Vergleiche mit der Binärdarstellung von p und q:\n"
            print "p binär:\n " + str(Integer(p).binary()) 
            
            q = testresult[1][0]^testresult[1][1]
            print "\nq binär: \n"
            print Integer(q).binary()
            return
        
    
    #Nun wird in die Inbox des Anwenders die Antwort geschrieben. Erstelle
    #dafür den zu übergebenden String.
    adresse = username + "@bit.uni-bonn.de"
    msgcontent = "begin_of_message|" + \
        "absender|Moneypenny|" +\
        "betreff|Re: " + subject + "|" + \
        "N|" + str(N) + "|" + \
        "e|" + str(e) + "|" + \
        "text|" + str(nachricht)
    #Verwandle den String in eine Zahl, um das Leerzeichen bei der Übergabe
    #an PHP zu vermeiden. Rückverwandlung beim Auslesen.
    msgcontent = text2num(msgcontent)
    fetchresult = fetch(ip, port, "/keyserver/moneypenny.php?mode=msgsent&username=" + adresse + \
                        "&content=" + str(msgcontent) )

#*************************************************************************
# mailto(adresse, subject, N, e, nachricht)
# 2 Fälle: Wenn Adresse moneypenny enthält, wird moneypenny das
# Schlüsselpaar untersuchen (zu knacken versuchen). Gelingt ihr das, so
# lehnt sie den Schlüssel ab. Andernfalls schreibt sie eine verschlüsselte
# Bestätigung in die Inbox des Nutzers. Enthält die Adresse eine
# (scheinbar) gültige Adresse eines anderen Teilnehmers, so wird die
# Nachricht in dessen inbox geschrieben.
#
# Um Massenaufrufe von mailto() per while-Schleife zu minimieren, wird 
# zu Beginn per Timer geprüft, ob die Funktion momentan aufgerufen werden darf.
#*************************************************************************
def mailto(adresse, subject, N, e, nachricht):
    if isinstance(nachricht, Integer) <> true:
        print "Bitte nur codierte Nachrichten verschicken.  Verwende num2text, um Nachrichten zu codieren"
        return false
    adresse = adresse.lower()
    if 'moneypenny' in adresse:
        return mailto_moneypenny(adresse, subject, N, e, nachricht)
    else: return mailto_user(adresse, subject, N, e, nachricht)

def nextprime(x):
    return Primes().next(x)

def random(lowerBound, upperBound):
    return sage.rings.integer.Integer(current_randstate().python_random().randrange(lowerBound,upperBound))
