**************************************************************************
* Import the DOF 2010-2060 population projections file (comma-delimited  *
* text file into SAS.  									                 *
* First line contains variables:				   						 *
*    Fips, Year, Sex, Race7, Agerc, and perwt (population)               *
**************************************************************************;

%let inpath = G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 7-2021;
libname std "G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 7-2021";

data pop1;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "&inpath.\P3_Complete.csv"
	delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Fips 4. ;
	informat Year 4. ;
	informat Sex $6. ;
	informat Race7 1. ;
	informat Agerc 3. ;
	informat Perwt best32. ;
	format Fips 4. ;
	format Year 4. ;
	format Sex $6. ;
	format Race7 1. ;
	format Agerc 3. ;
	format Perwt best32. ;
	input
	Fips
	Year 
	Sex $
	Race7
	Agerc
	Perwt
	;
	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

* Merge in county names and recode sex and race ;
proc sql;
	create table pop2 as
	select b.county, a.year, 
		substr(a.sex,1,1) as Sex format $1., 
		case when a.agerc > 100 then 100 
			 else a.agerc end as Age format 3. informat 3.,
		case when a.race7=1 then 'W'
			 when a.race7=2 then 'B'
			 when a.race7=3 then 'I'
			 when a.race7=4 then 'A'
			 when a.race7=5 then 'P'
			 when a.race7=6 then 'M'
			 when a.race7=7 then 'H'
			 else 'U' end as RE format $1.,
		a.perwt as POP
	from pop1 as a
	left join std.cnty_fips as b
	on a.fips = b.fips;
quit;

* Sum up population for the 100+ year-olds;
proc sql;
	create table pop3 as
	select COUNTY, YEAR, SEX, AGE, RE, sum(POP) as POP
	from pop2
	group by county, year, sex, re, age;
quit;

* Create state totals for each year, sex, age, re combination;
proc sql;
	create table pop4 as
	select 'California' as COUNTY, YEAR, SEX, AGE, RE, sum(POP) as POP
	from pop3
	group by year, sex, re, age;
quit;


* Save to a permanent dataset;
proc sql;
	create table std.arspop_2010_2025 as
	select COUNTY, YEAR, SEX, AGE, RE, POP
	from pop3
	where Year <= 2025
	union
	select COUNTY, YEAR, SEX, AGE, RE, POP
	from pop4
	where Year <= 2025
	order by county, year, sex, re, age;
quit;
