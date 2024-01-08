#!/usr/bin/env python

WordisUsageStr = "\n\
Usage: pwordis.py <Options>\n\
Options:\n\
    -h              : Display this help message and exit\n\
    -a              : Use many-letter word (refer PlayHow); default=-u TODO\n\
    -p <NumPlayers> : Number of players; default = 1 TODO\n\
    -l <WordLength> : Length of word(s) to be played; Default=4\n\
    -m <MaxGueses>  : Guesses limit; then game is lost; Default=14\n\
    -g              : Use GUI mode to play; Default=terminal TODO\n\
\n\
PlayHow: \n\
> Secret word length range: 2 to 8\n\
> In Unique-letter mode, words have unique letters\n\
   e.g. Good - able, to, prank, got;; Bad - abate, ball, cleanse\n\
> In Any-letter mode, words can have a letter twice or more\n\
   e.g. Good - roar, abate, eve\n\
> Words are never nouns or names\n\
   e.g. Good - gone, no, thicker;; Bad - raju, bruce, michael\n\
> Clues are given for each guess using combo of * and/or ^ on match\n\
   *    - a letter in guess is in same position in secret\n\
   ^    - a letter in guess is in different position in secret\n\
   ---- - occurs if no letter in guess matches with secret\n\
> Input 'H' to display your guess history\n\
> Input 'R' to remove letter(s) if sure of absence in secret\n\
   e.g. R b\n\
        R xqy\n\
> Input 'A' to display letters not confirmed of absence\n\
   e.g. a b c e h .. z => d, f, g are confirmed absent in secret\n\
        and a,b,c,e,h..z MIGHT be present in secret\n\
> In case a guess has no match at all with secret, result is '----'\n\n"

# App starts @ SOPS

import os
import sys
import time
import re
import platform
import getopt
import os.path
import random
#import threading
#import pdb

######################### Wordis-Game-Environment (WENV)
gUseUniqLetterWords = True
gNumPlayers = 1
gWordLen = 4
gMaxGuesses = 14
gUseGUI = False
gABC = list ("abcdefghijklmnopqrstuvwxyz")
gSecret = "----"
gDictFile = "/usr/share/dict/american-english"
gDictInfoFile = os.path.expanduser("~/.en-dict-info.txt")
gNumDictWords = 0
gNumDictLetters = 0
gGuesses = []
gClues = []
gOldTattr = 0
gNewTattr = 0

UsingTermios = True

######################### Helper/Handler Functions 

# Function to write IRRECOVERABLE error msg to stdout and log-file (if open)
# and then exit the program
# Usage  : ErrExit (msg)
#          msg - message to be written
# Return : None
def ErrExit (msg) :
    print ("\n!ERROR!: " + msg + "\n")
    quit ()

# Function to open given file in requested mode and print error info, if any
# Usage  : OpenFile (fname, mode, create_absent)
#          fname - file to open
#          mode  - mode to open file
#          create_absent - create if file is absent
# Return : Valid File-Handle for success
#          None for failure
def OpenFile (fname, mode, create_absent) :
    try : fh = open(fname, mode); return fh
    except OSError : print ("Failed to open " +fname)
    if not create_absent : return None
    try : print ("Creating " +fname); fh = open(fname, "w+"); return fh
    except OSError : print ("Failed to create " +fname); return None

# Function to validate word w.r.t game mode
# Usage  : ValidateWord (word)
#          word  - word to validate
# Return : 0 for success
#          -1 for failure
def ValidateWord (word) :
    if len (word) != gWordLen : return -1
    lABC = list ("abcdefghijklmnopqrstuvwxyz")
    for i in range (0, gWordLen) :
        if word[i] not in lABC : return -2
        elif gUseUniqLetterWords :
            # disallow letter re-occurrance in uniq-mode!
            if lABC[ord(word[i])-ord('a')] == 0 : return -3
            else : lABC[ord(word[i])-ord('a')] = 0
    return gWordLen

def ReadInput () :
    buf = []
    while UsingTermios :
        c = sys.stdin.read (1)
        if c == '\x1b' and sys.stdin.read(1) == '[' :
            sys.stdin.read(1); continue; # '\x1b[A'
        elif c in "abcdefghijklmnopqrstuvwxyz AHR" : buf.append (c)
        elif c == '\n' : return "".join (buf)
        elif c == '\x7f' : c = "\b \b"
        if c == 'A' : print ("A ", end=''); return "A".join (buf)
        if c == 'H' : print ("H ", end=''); return "H".join (buf)
        if c != "\b \b" or buf : sys.stdout.write (c); sys.stdout.flush ()
        if buf and c == "\b \b" : buf.pop ()
    return input ()

# Function to get a valid guess-word
# Usage  : GetNextGuess (GuessCnt)
#          GuessCnt - Number of guesses made so far
# Return : Valid guess-word
#          OR Guess-control-cmd (A, H, R, etc)
def GetNextGuess (GuessCnt) :
    labc="abcdefghijklmnopqrstuvwxyz"
    while True :
        print ("%02u: " %(GuessCnt+1), end=''); sys.stdout.flush ()
        guess = ReadInput ()
        #print ("\nguess : " + guess)
        if guess in ['A', 'H'] or guess[:2] == "R " : return guess
        ret = ValidateWord (guess)
        if ret == gWordLen : return guess
        elif ret == -1 :
            print (" ERR: Expected length: %u\r" %gWordLen, end='')
        elif ret == -2 :
            print (" ERR: Allowed letters: %s\r" %labc, end='')
        elif ret == -3 :
            print (" ERR: Not Uniq-letter word: %s\r" %guess, end='')

# Function to process a new valid guess
# Usage  : ProcessThisGuess (guess, nGuesses)
#          guess    - word guessed for secret
#          nGuesses - current guess number
# Return : 0 for correct match with secret
#          -1 for no match at all with secret
#          1 for partial letter/position match with secret
def ProcessThisGuess (guess, nGuesses) :
    ci = 0
    lclue = list ('-'*gWordLen)
    lfound = []
    i = random.randint (0, gWordLen-1)
    wlen = gWordLen
    while wlen :
        c = guess[i]
        if (c in gSecret) and (c not in lfound) :
            lclue[ci] = '*' if (c == gSecret[i]) else '^'
            lfound.append (c)
            ci += 1
        wlen -= 1
        i = 0 if (i == gWordLen-1) else (i+1)
    return "".join (lclue)

######################### Start-Of-Python-Script (SOPS)

gPyVer = int (platform.python_version()[0])
if gPyVer != 3 : ErrExit ("Python version must be 3 or newer")

# Validate arguments and setup game environment
opts, args = getopt.getopt(sys.argv[1:], 'a:p:l:m:hg')
for opt, arg in opts :
    if opt == "-h" : sys.exit (WordisUsageStr)
    elif opt == "-a" :
        print ("Forcing Uniq-letter-mode; -a is not supported yet"); continue
        gUseUniqLetterWords = False
    elif opt == "-p" :
        gNumPlayers = int (arg) if len (arg) else 1
        if gNumPlayers > 1 : print ("NumPlayers=1 for now\n"); gNumPlayers = 1
    elif opt == "-l" :
        gWordLen = int (arg) if len (arg) else 4
        if gWordLen > 8 : ErrExit ("Max length is 8\n" + WordisUsageStr)
    elif opt == "-m" :
        gMaxGuesses = int (arg) if len (arg) else 14
    elif opt == "-g" :
        print ("Disableing GUI mode as it's not supported yet"); continue
        gUseGUI = True

# Setup Secret word
# Currently 1 player + UniqLetterWord mode is defined
if gNumPlayers == 1 :
    # Open dict (and info) file(s) as needed
    SetupDictInfoAfresh = False
    dfh = OpenFile (gDictFile, "rt", False)
    if not dfh : sys.exit ("Exiting")
    ifh = OpenFile (gDictInfoFile, "r+", True)
    if not ifh : ifh.close (); sys.exit ("Exiting")
    buf1 = ifh.readline ()
    if buf1 and ("gNumDictWords" in buf1) :
        buf2 = ifh.readline ()
        if buf2 and ("gNumDictLetters" in buf2) :
            # Update dict words/letters count
            gNumDictWords = int (buf1[len ("gNumDictWords: "):])
            gNumDictLetters = int (buf2[len ("gNumDictLetters: "):])
        else : SetupDictInfoAfresh = True
    else : SetupDictInfoAfresh = True
    # Setup dict info file if needed
    if SetupDictInfoAfresh :
        print ("Creating dict-info. May take a while..")
        ifh.seek (0)
        # Get number of words and letters in gDictFile
        for line in dfh :
            gNumDictWords += 1
            gNumDictLetters += len (line)
        ifh.write ("gNumDictWords: %u\n" % gNumDictWords)
        ifh.write ("gNumDictLetters: %u\n" % gNumDictLetters)
    ifh.close ()
    # Try read a line randomly till we get a valid word
    while True :
        ret = random.randrange (0, gNumDictLetters, 1)
        dfh.seek (ret)
        # dfh may point to mid-of-line, so skip this line
        if not dfh.readline () : continue
        # dfh may point to new-line or EOF
        buf = dfh.readline ()
        if not buf : continue
        buf = buf.rstrip ("\n")
        if len (buf) != gWordLen : continue
        ret = ValidateWord (buf)
        if ret == gWordLen : gSecret = buf; break
    # close any open files and return 
    dfh.close ()

# Setup termios to control input and newline
if not gUseGUI and UsingTermios :
    import termios
    fd = sys.stdin.fileno()
    gOldTattr = termios.tcgetattr(fd)
    gNewTattr = termios.tcgetattr(fd)
    gNewTattr[3] = gNewTattr[3] & ~termios.ICANON & ~termios.ECHO
    termios.tcsetattr(fd, termios.TCSANOW, gNewTattr)

# Let the games begin
lPlayerWon = False
lGuessCnt = 0
while lGuessCnt < gMaxGuesses :
    guess = GetNextGuess (lGuessCnt)
    # 'A' => display possible alphabets in secret
    if guess == "A" : print (" ",end=''); print ([i for i in gABC if i ])
    # 'H' => display guess history
    elif guess == "H" :
        print ("")
        for i in range (0, lGuessCnt) :
            print ("--- %02u: %s = %s" %(i+1, gGuesses[i], gClues[i]))
    # 'R' => remove letters user thinks absent in secret
    elif guess[:2] == "R " :
        rml = guess[2:].lower ()
        for i in range (0, len (rml)) : gABC[ord(rml[i])-ord('a')] = 0
        print ("")
    # Skip this guess if it's already given before
    elif guess in gGuesses :
        if UsingTermios : print (" guessed already")
        else  : print ("%s guessed already!" %guess)
    # Process this new valid guess
    else :
        sclue = ProcessThisGuess (guess, lGuessCnt)
        gGuesses.append (guess)
        gClues.append (sclue)
        if UsingTermios : print (" - " + gClues[lGuessCnt] + " "*20)
        else : print (guess + " - " + gClues[lGuessCnt])
        if sclue == '*'*len (sclue) : lPlayerWon = True; break
        elif sclue == '-'*len (sclue) : # None of letters/positions matched
            for i in range (0, gWordLen) : gABC[ord(guess[i])-ord('a')] = 0
        lGuessCnt += 1

if UsingTermios : termios.tcsetattr(fd, termios.TCSAFLUSH, gOldTattr)

if lPlayerWon : print ("You win @ trial %u. Word-is %s" %(lGuessCnt+1, gSecret))
else : print ("Yoo LOSE! Word-is still secret ;p")

quit ()
