/* Create city age/race/sex estimates for combining with DOF population projection data */
/* only edit libname proj4new if the ARS file is updated */





libname all "G:\STD\STD Data\Population";
libname std "G:\STD\STD Data\Population\DOF";
libname proj1 "G:\STD\STD Data\Population\DOF\ARS 1970-1989 Rev 12-1998";
libname proj2 "G:\STD\STD Data\Population\DOF\ARS 1990-1999 Rev 5-2009";
libname proj3 "G:\STD\STD Data\Population\DOF\ARS 2000-2050 Rev 7-2007";
libname proj3new "G:\STD\STD Data\Population\DOF\ARS 2000-2010 Rev 9-2012";
*libname proj4 "G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 1-2013";
*libname proj4 "G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 12-2014";
*libname proj4 "G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 2-2017";
libname proj4new "G:\STD\STD Data\Population\DOF\ARS 2010-2060 Rev 7-2021";


* Combine city census with July 1 city estimates - using 2000 census ratios against pre-2010 years
  and 2010 for current years;
proc sql;
	create table city_ars as
	select b.LHJ as COUNTY format $15., b.YEAR, a.SEX, a.AGE, a.RE, a.RATIO*b.POP as POP
	from  std.cities_2000census as a
	INNER JOIN all.july1est_1947_cy (where=(year<2010)) as b
	on a.city = b.lhj
	union
	select b.LHJ as COUNTY format $15., b.YEAR, a.SEX, a.AGE, a.RE, a.RATIO*b.POP as POP
	from  std.cities_2010census as a
	INNER JOIN all.july1est_1947_cy (where=(year>=2010)) as b
	on a.city = b.lhj;
quit;

* Reassign race values depending on county race values by year;
*	1970-1989 projection data has A, B, H, I, W, and O (=0 for all);
*	1990-1999 projection data has A, B, H, I, W, and O (=0 for all);
*	2000-2009 projection data has A, B, H, I, W, P, M, O;
*	2010-2060 projection data has A, B, H, I, W, P, M;
data city_ars2;
	set city_ars;
	if year <= 1999 and re = 'P' then re = 'A';
	* Reassign M and O to W for years through 1999;
	if year <= 1999 and re in ('M','O') then re = 'W';
/*	if 2000 <= year <= 2009 and re = 'M' then re = 'O';*/
	/* DOF projections did not have an O category - may want to consider recoding to M or W */
	/* Until then, Alameda HD plus Berkeley will not necessarily add to Alameda */
	/* 8/13/2013 talked some with Michael Samuel about the issue, but will leave be for now */
	/* 1/13/2016 decided to recode 'O' to 'W' for now */
	if re = 'O' then re = 'W';
run;
proc sql;
	create table city_ars3 as
	select COUNTY, YEAR, SEX, AGE, RE, sum(POP) as POP
	from city_ars2
	group by COUNTY, YEAR, SEX, AGE, RE;
quit;

* Combine the population projections data containing counties and state;
proc sql;
	create table ars_1 as
	select *
	from proj1.arspop_1970_1989
	where year >= 1980
	union
	select *
	from proj2.arspop_1990_1999
	union
	select *
	from proj3new.arspop_2000_2009
	union
	select *
	from proj4new.arspop_2010_2025
	;
quit;

* Calculate ratios of each county/year/age/race/sex category to the ;
* respective overall county total for that year, then multiply that ;
* ratio by the DOF July 1 estimates.  This will ensure matching of  ;
* the totals from ARS with the July 1 numbers.                      ;
proc sql;
	create table ars_totals as
	select county, year, sum(pop) as TotalPop
	from ars_1
	group by county, year;
quit;
proc sql;
	create table ars_2 as
	select a.county, a.year, a.sex, a.age, a.re, a.pop as OrigPop, (a.pop/b.totalpop) as TotalRatio, b.totalpop, 
		case when c.pop = . then b.totalpop else c.pop end as JulyPop, ((calculated julypop)*a.pop/b.totalpop) as POP
	from ars_1 as a
	left join ars_totals as b
	on a.county = b.county
	and a.year = b.year
	left join all.july1est_1947_cy as c
	on a.county = c.lhj
	and a.year = c.year;
quit;

* Calculating the difference between the Alameda and Los Angeles county ARS population;
* and the estimated city ARS population to derive Alameda HD and Los Angeles HD;
data HD_ars;
	set city_ars3;
	length belongs_to_county $15;
	if COUNTY ="Berkeley" then 
		do;
			COUNTY = 'Alameda HD';
			belongs_to_county = 'Alameda';
		end;
	else if COUNTY in ("Long Beach","Pasadena") then 
		do;
			COUNTY = 'Los Angeles HD';
			belongs_to_county = 'Los Angeles';
		end;
run;
proc sql;
	create table hd_ars2 as
	select COUNTY, belongs_to_county, YEAR, SEX, AGE, RE, sum(POP) as citypop
	from HD_ars
	group by COUNTY, belongs_to_county, YEAR, SEX, AGE, RE;
quit;
proc sql;
	create	table HD_ars3 as
	select	a.COUNTY, a.YEAR, a.SEX, a.AGE, a.RE, max(0,b.pop) as cntypop format best12., a.citypop, 
		max(0,b.pop-a.citypop) as POP
	from	HD_ars2 as a
	LEFT JOIN ars_2 as b
	on		a.belongs_to_county = b.county
	and		a.year = b.year
	and		a.sex = b.sex
	and 	a.age = b.age
	and		a.re = b.re
	;
quit;


* Creating the combined county, state, and city/HD ARS files;
proc sql;
	create table all.arspop_1980_2025 as
	select COUNTY, YEAR, SEX, AGE, RE, OrigPop format best12., POP format best12.
	from ars_2
	union
	select COUNTY, YEAR, SEX, AGE, RE, . as OrigPop format best12., POP format best12.
	from city_ars3
	union
	select COUNTY, YEAR, SEX, AGE, RE, . as OrigPop format best12., POP format best12.
	from hd_ars3
	;
quit;


