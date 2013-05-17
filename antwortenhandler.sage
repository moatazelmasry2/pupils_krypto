# -*- coding: utf-8 -*- 
from antworten import *

class AntwortenHandler(Antworten):

    set_random_seed(31)
    myrandom = current_randstate().python_random()
    
    lehrertexte = []
    schultexte = []
    antwortentext = []
    
    def __init__(self):
        #Antworten.__init__(self)
        lehrertexte = [self.einigelehrerfmt(l) for l in self.lehrer]
        #print self.lehrer
        #print lehrertexte
        
        #print self.schulen
        schultexte = [self.einigeschulfmt(s) for s in self.schulen]
        #print schultexte
        #print [l for l in schultexte]
        self.antwortentext += lehrertexte + schultexte
    
    
    def lehrerfmt(self, l, t ):
        if "%s-n" in t:
            t.replace("%s-n", l.replace("Herr", "Herrn"))
        else:
            t.replace("%s",l)
        return t
    
    def einigelehrerfmt(self, l ):
        for i in range(0,4):
            result = self.lehrerfmt( l, self.lehrerschablonen[self.myrandom.randrange(0,len(self.lehrerschablonen))])
        return result 
    #def msubs(x,S):
    #    x = stringlib::subs( x, S );
    #    if args(0)>2 : 
    #        x=msubs( x, args(3..args(0)) )
    #    return x
    
    def schulfmt(self, s,t):
        x = t[ t.find("%s-" ) +3 ]
        #There is no switch case in python. so far I didn't like the available workarounds
        #TODO replace the several replace statements with something more elegant
        
        if "r" == x:
            z = t.replace("%s-r",s )
          
        elif "s" == x:
          z = t.replace("%s-s", s.replace("der","des").replace("die","der").replace("das","des").\
                        replace("Gymnasium","Gymnasiums").replace("Kolleg","Kollegs" ) )
        elif "m" == x:
            z = t.replace("%s-m", s.replace("der","dem").replace("die","der").replace("das","dem" ) )
        elif "n" == x or "m" == x:
          z = t.replace("%s-n", s.replace("der","den").replace("die","die").replace("das","das" ) )
        
        z = z.replace("an dem","am").replace("in dem","im").replace("bei dem","beim").replace("an das","ans").replace\
            ("in das","ins").replace("'der ","'").replace("'die ","'").replace("'das ","'")
         #stringlib::upper( z[1] ) . z[2..-1];
        return z[0].upper() + z[1:len(z)]
    
    
    def einigeschulfmt(self, s):
        for i in range (1,5):
            z = self.schulfmt( s, self.schulschablonen[self.myrandom.randrange(1,len(self.schulschablonen) ) ] )
            #if z == 5: return z
        return z
    