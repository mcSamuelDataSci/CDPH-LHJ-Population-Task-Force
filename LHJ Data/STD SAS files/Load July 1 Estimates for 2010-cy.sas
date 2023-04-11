/* Converting DOF population excel files into SAS datasets  */
/* Updated on Aug 18, 2022 by J.Hu to include a macro that decides the most recent year (lines 11 and 50) */





%let inpath = G:\STD\STD Data\Population\DOF\July 1 Estimates;
libname std "G:\STD\STD Data\Population\DOF";
* maxyr is the most recent year, revise if needed;
%let maxyr = 2021;

*Import raw county data;
proc import	out 		= e6_raw10
				/* Revise datafile to use the most recent DOF export available */
			datafile 	= "&inpath.\E-6_Report_July_2010-2021_w.xlsx" 
			dbms 		= excel
			replace
			;
			getnames 	= no;
			mixed		= yes;
				/* Revise sheet to use the most recent sheet name */
			sheet		= "E-6 2010-2021 Report";
				/* Revise range to run from 1st Calfornia row to last Yuba row */
			range		= "A6:C772";
run;

data std.july1est_2010_cy_cnty (keep = lhj year pop);
	length LHJ $15;
	set e6_raw10;
	*Only a few of the rows have county names, so we need to get them all filled in.  For that,
	we use a buffer variable with a RETAIN statement to carry values from one observation to
	the next.  For rows where F1 is missing we fill it in from the buffer, otherwise we take
	the name from the row and put it in the buffer;
	retain buffer; if f1 = ' ' then f1 = buffer; else buffer = f1;
	*fix the broken county names;
	if 		f1 = 'Costa' 		then lhj = 'Contra Costa';
	else if f1 = 'Angeles' 		then lhj = 'Los Angeles';
	else if f1 = 'Bernardino' 	then lhj = 'San Bernardino';
	else if f1 = 'Francisco' 	then lhj = 'San Francisco';
	else if f1 = 'Joaquin' 		then lhj = 'San Joaquin';
	else if f1 = 'Obispo' 		then lhj = 'San Luis Obispo';
	else if f1 = 'Barbara' 		then lhj = 'Santa Barbara';
	else if f1 = 'Clara' 		then lhj = 'Santa Clara';
	else lhj = f1;
	*rename some variables;
	if f2 = 'Census 2010' then delete;
	if f2 = 'Apr-Jun 2010' then YEAR = 2010; else YEAR = input(f2,4.);
	POP = f3;
	if 2010 <= year <= &maxyr. then output;
run;
