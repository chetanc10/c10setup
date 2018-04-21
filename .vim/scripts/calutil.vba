" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/calutil.vim	[[[1
153
" calutil.vim: some calendar utilities
" Author:	Charles E. Campbell, Jr.
" Date:		Oct 08, 2008
" Version:	3b	ASTRO-ONLY
" ---------------------------------------------------------------------
if exists("loaded_calutil")
 finish
endif
let g:loaded_calutil= "v3b"
if v:version < 700
 echohl WarningMsg
 echo "***warning*** this version of calutil needs vim 7.0"
 echohl Normal
 finish
endif

" ---------------------------------------------------------------------
" DayOfWeek: {{{1
" Usage :  call calutil#DayOfWeek(y,m,d,[0|1|2])
"   g:CalUtilDayOfWeek: if 0-> integer (default)
"                          1-> 3-letter English abbreviation for name of day
"                          2-> English name of day
" Returns
" g:CalUtilDayOfWeek
" ---------
" 		1  :  0      1       2         3        4      5        6
" 		2  : Mon    Tue     Wed       Thu      Fri    Sat      Sun
"       3  : Monday Tuesday Wednesday Thursday Friday Saturday Sunday
fun! calutil#DayOfWeek(y,m,d,...)
  if a:0 > 0
   let g:CalUtilDayOfWeek= a:1
  endif

  let z= Cal2Jul(a:y,a:m,a:d)
  if z >= 0
   let z= z%7
  else
   let z= 7 - (-z%7)
  endif

  if exists("g:CalUtilDayOfWeek")
   if g:CalUtilDayOfWeek == 2
	let dow0="Mon"
	let dow1="Tue"
	let dow2="Wed"
	let dow3="Thu"
	let dow4="Fri"
	let dow5="Sat"
	let dow6="Sun"
	return dow{z}
   elseif g:CalUtilDayOfWeek == 3
	let dow0="Monday"
	let dow1="Tuesday"
	let dow2="Wednesday"
	let dow3="Thursday"
	let dow4="Friday"
	let dow5="Saturday"
	let dow6="Sunday"
	return dow{z}
   endif
  endif
  return z
endfun

" ---------------------------------------------------------------------
" calutil#Cal2Jul: convert a (after 9/14/1752) Gregorian calendar date to Julian day {{{1
"                    (on,before  "   ) Julian calendar date to Julian day
"                                      (proleptic)
fun! calutil#Cal2Jul(y,m,d)
  let year = a:y
  let month= a:m
  let day  = a:d

  " there is no year zero
  if year == 0
   let year= -1
  elseif year < 0
   let year= year + 1
  endif

  let julday= day - 32075 +
	 \               1461*(year  + 4800 +  (month - 14)/12)/4      +
	 \                367*(month - 2    - ((month - 14)/12)*12)/12 -
	 \                  3*((year + 4900 +  (month - 14)/12)/100)/4

  " 2361221 == Sep  2, 1752, which was followed immediately by
  "            Sep 14, 1752  (in England).  Various countries
  "            adopted the Gregorian calendar at different times.
  if julday <= 2361221
   let a      = (14-month)/12
   let y      = year + 4800 - a
   let m      = month + 12*a - 3
   let julday = day + (153*m + 2)/5 + y*365 + y/4 - 32083
  endif
  return julday
endfun

" ---------------------------------------------------------------------
" calutil#Jul2Cal: convert a Julian day to a date: {{{1
"     Default    year/month/day
"     julday,1   julday,"ymd" year/month/day
"     julday,2   julday,"mdy" month/day/year
"     julday,3   julday,"dmy" day/month/year
fun! calutil#Jul2Cal(julday,...)
  let julday= a:julday

  if julday <= 2361221
   " Proleptic Julian Calendar:
   " 2361210 == Sep 2, 1752, which was followed immediately by Sep 14, 1752
   " in England
   let c     = julday + 32082
   let d     = (4*c + 3)/1461
   let e     = c - (1461*d)/4
   let m     = (5*e + 2)/153
   let day   = e - (153*m + 2)/5 + 1
   let month = m + 3 - 12*(m/10)
   let year  = d - 4800 + m/10
   if year <= 0
    " proleptic Julian Calendar: there *is* no year 0!
    let year= year - 1
   endif

  else
   " Gregorian calendar
   let t1    = julday + 68569
   let t2    = 4*t1/146097
   let t1    = t1 - (146097*t2 + 3)/4
   let yr    = 4000*(t1 + 1)/1461001
   let t1    = t1 - (1461*yr/4 - 31)
   let mo    = 80*t1/2447
   let day   = (t1 - 2447*mo/80)
   let t1    = mo/11
   let month = (mo + 2 - 12*t1)
   let year  = (100*(t2 - 49) + yr + t1)
  endif

  if a:0 > 0
   if a:1 == 1 || a:1 =~ "ymd"
    return year."/".month."/".day
   elseif a:1 == 2 || a:1 =~ "mdy"
    return month."/".day."/".year
   elseif a:1 == 3 || a:1 =~ "dmy"
    return day."/".month."/".year
   else
    return year."/".month."/".day
   endif
  else
   return year."/".month."/".day
  endif
endfun

" ---------------------------------------------------------------------
" vim: ts=4 fdm=marker
doc/calutil.txt	[[[1
66
*calutil.txt*	DrChip's Calendar Utilities			Oct 17, 2007

Author:  Charles E. Campbell, Jr.  <NdrchipO@ScampbellPfamily.AbizM> {{{1
Copyright:    Copyright (C) 2007 Charles E. Campbell, Jr. {{{1
              Permission is hereby granted to use and distribute this code,
              with or without modifications, provided that this copyright
              notice is copied with it. Like anything else that's free,
              calutil.vim is provided *as is* and comes with no warranty
              of any kind, either expressed or implied. By using this
              plugin, you agree that in no event will the copyright
              holder be liable for any damages resulting from the use
              of this software.


==============================================================================
1. Contents				*calutil* *calutil-contents* {{{1

   1. Contents.............................: |calutil-contents|
   2. Calutil Manual.......................: |calutil-manual|
   3. History..............................: |calutil-history|

==============================================================================
2. Calutil Manual					*calutil-manual* {{{1

	DAY OF WEEK~
	Usage  : call calutil#DayOfWeek(y,m,d [,style])
	Purpose: to determine the day of the week given a calendrical date
	Returns: g:CalUtilDayOfWeek saves the style
					0-> integer (default)
					1-> 3-letter English abbreviation for
					    name of day
					2-> English name of day

	 STYLE : The function itself returns:
	    0  :  0      1       2         3        4      5        6
	    1  : Mon    Tue     Wed       Thu      Fri    Sat      Sun
	    2  : Monday Tuesday Wednesday Thursday Friday Saturday Sunday

	CONVERT DATE TO JULIAN DAY~
	Usage  : call calutil#Cal2Jul(y,m,d) :
	Purpose: converts a calendrical, numerical date into Julian day
	         The input date is assumed to be Gregorian after 9/14/1752
		 and a (proleptic) Julian date prior to that.
	Returns: an integer; ie. the number of days since January 1, 4713BC.
	         January 1, 4713BC corresponds to a Julian day of zero.

	CONVERT JULIAN DAY TO CALENDRICAL DATE~
	Usage  : call calutil#Jul2Cal(julday [,"ymd" -or- "mdy" -or- "dmy"])
	Usage  : call calutil#Jul2Cal(julday [,  1   -or-   2   -or-   3  ])
	Purpose: converts a Julian day into a date

	    Default    year/month/day
	    julday,1   julday,"ymd" year/month/day
	    julday,2   julday,"mdy" month/day/year
	    julday,3   julday,"dmy" day/month/year

==============================================================================
3. History						*calutil-history* {{{1

   2  Jul 27, 2004 :
      Oct 17, 2007 : it was pointed out to me that calutil.txt wasn't a help
                     file; so it was written this day.
   1               : the epoch

 ---------------------------------------------------------------------
vim:tw=78:ts=8:ft=help:fdm=marker
autoload/calutil.vim	[[[1
153
" calutil.vim: some calendar utilities
" Author:	Charles E. Campbell, Jr.
" Date:		Oct 08, 2008
" Version:	3b	ASTRO-ONLY
" ---------------------------------------------------------------------
if exists("loaded_calutil")
 finish
endif
let g:loaded_calutil= "v3b"
if v:version < 700
 echohl WarningMsg
 echo "***warning*** this version of calutil needs vim 7.0"
 echohl Normal
 finish
endif

" ---------------------------------------------------------------------
" DayOfWeek: {{{1
" Usage :  call calutil#DayOfWeek(y,m,d,[0|1|2])
"   g:CalUtilDayOfWeek: if 0-> integer (default)
"                          1-> 3-letter English abbreviation for name of day
"                          2-> English name of day
" Returns
" g:CalUtilDayOfWeek
" ---------
" 		1  :  0      1       2         3        4      5        6
" 		2  : Mon    Tue     Wed       Thu      Fri    Sat      Sun
"       3  : Monday Tuesday Wednesday Thursday Friday Saturday Sunday
fun! calutil#DayOfWeek(y,m,d,...)
  if a:0 > 0
   let g:CalUtilDayOfWeek= a:1
  endif

  let z= Cal2Jul(a:y,a:m,a:d)
  if z >= 0
   let z= z%7
  else
   let z= 7 - (-z%7)
  endif

  if exists("g:CalUtilDayOfWeek")
   if g:CalUtilDayOfWeek == 2
	let dow0="Mon"
	let dow1="Tue"
	let dow2="Wed"
	let dow3="Thu"
	let dow4="Fri"
	let dow5="Sat"
	let dow6="Sun"
	return dow{z}
   elseif g:CalUtilDayOfWeek == 3
	let dow0="Monday"
	let dow1="Tuesday"
	let dow2="Wednesday"
	let dow3="Thursday"
	let dow4="Friday"
	let dow5="Saturday"
	let dow6="Sunday"
	return dow{z}
   endif
  endif
  return z
endfun

" ---------------------------------------------------------------------
" calutil#Cal2Jul: convert a (after 9/14/1752) Gregorian calendar date to Julian day {{{1
"                    (on,before  "   ) Julian calendar date to Julian day
"                                      (proleptic)
fun! calutil#Cal2Jul(y,m,d)
  let year = a:y
  let month= a:m
  let day  = a:d

  " there is no year zero
  if year == 0
   let year= -1
  elseif year < 0
   let year= year + 1
  endif

  let julday= day - 32075 +
	 \               1461*(year  + 4800 +  (month - 14)/12)/4      +
	 \                367*(month - 2    - ((month - 14)/12)*12)/12 -
	 \                  3*((year + 4900 +  (month - 14)/12)/100)/4

  " 2361221 == Sep  2, 1752, which was followed immediately by
  "            Sep 14, 1752  (in England).  Various countries
  "            adopted the Gregorian calendar at different times.
  if julday <= 2361221
   let a      = (14-month)/12
   let y      = year + 4800 - a
   let m      = month + 12*a - 3
   let julday = day + (153*m + 2)/5 + y*365 + y/4 - 32083
  endif
  return julday
endfun

" ---------------------------------------------------------------------
" calutil#Jul2Cal: convert a Julian day to a date: {{{1
"     Default    year/month/day
"     julday,1   julday,"ymd" year/month/day
"     julday,2   julday,"mdy" month/day/year
"     julday,3   julday,"dmy" day/month/year
fun! calutil#Jul2Cal(julday,...)
  let julday= a:julday

  if julday <= 2361221
   " Proleptic Julian Calendar:
   " 2361210 == Sep 2, 1752, which was followed immediately by Sep 14, 1752
   " in England
   let c     = julday + 32082
   let d     = (4*c + 3)/1461
   let e     = c - (1461*d)/4
   let m     = (5*e + 2)/153
   let day   = e - (153*m + 2)/5 + 1
   let month = m + 3 - 12*(m/10)
   let year  = d - 4800 + m/10
   if year <= 0
    " proleptic Julian Calendar: there *is* no year 0!
    let year= year - 1
   endif

  else
   " Gregorian calendar
   let t1    = julday + 68569
   let t2    = 4*t1/146097
   let t1    = t1 - (146097*t2 + 3)/4
   let yr    = 4000*(t1 + 1)/1461001
   let t1    = t1 - (1461*yr/4 - 31)
   let mo    = 80*t1/2447
   let day   = (t1 - 2447*mo/80)
   let t1    = mo/11
   let month = (mo + 2 - 12*t1)
   let year  = (100*(t2 - 49) + yr + t1)
  endif

  if a:0 > 0
   if a:1 == 1 || a:1 =~ "ymd"
    return year."/".month."/".day
   elseif a:1 == 2 || a:1 =~ "mdy"
    return month."/".day."/".year
   elseif a:1 == 3 || a:1 =~ "dmy"
    return day."/".month."/".year
   else
    return year."/".month."/".day
   endif
  else
   return year."/".month."/".day
  endif
endfun

" ---------------------------------------------------------------------
" vim: ts=4 fdm=marker
