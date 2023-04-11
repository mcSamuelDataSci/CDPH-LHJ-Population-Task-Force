/* Converting DOF E-1 population excel files for 2010-current yr into SAS datasets  */

%let inpath = G:\STD\STD Data\Population\DOF\Jan 1 Estimates;
libname std "G:\STD\STD Data\Population\DOF";
libname all "G:\STD\STD Data\Population";

*Import raw 2010 E-1 city data, only from specified cell range;
proc import	out 		= e1_raw_city
			datafile 	= "&inpath.\E-1_2011_Internet_Version.xls" 
			dbms 		= excel
			replace
			;
			sheet		= "E-1 CityCounty2011$";
			range		= "A6:B658";
run;
*Clean up the data a bit: keep Berkeley, Pasadena, and Long Beach, rename variables;
data e1_cities10 (keep = lhj year pop belongs_to_county);
	length LHJ belongs_to_county $15;
	set e1_raw_city;
	LHJ = F1;
	if lhj = 'Berkeley' then belongs_to_county = 'Alameda';
	else if lhj in('Long Beach','Pasadena') then belongs_to_county = 'Los Angeles';
	*create output records that associate the Excel columns with years;
	array years{*} f2;
	do i = 1 to dim(years);
		YEAR = 2010+i-1;
		POP = years{i};
		if year = 2010 then do;
			if lhj in ('Berkeley','Long Beach','Pasadena') then do;
				output;
			end;
		end;
	end;
run;


*Import raw 2010 E-1 county data, only from specified cell range;
proc import	out 		= e1_raw_county
			datafile 	= "&inpath.\E-1_2011_Internet_Version.xls" 
			dbms 		= excel
			replace
			;
			sheet		= "E-1 CountyState2011$";
			range		= "A6:B66";
run;
*Clean up the data a bit: keep Alameda, and Los Angeles, rename variables;
data e1_counties10(keep = lhj year pop);
	length LHJ $15;
	set e1_raw_county;
	LHJ = trim(substr(F1,3,13));  /* strip out leading space */
	*create output records that associate the Excel columns with years;
	array years{*} f2;
	do i = 1 to dim(years);
		YEAR = 2010+i-1;
		POP = years{i};
		if year = 2010 then do;
			if lhj in('Alameda','Los Angeles') then do;
				output;
			end;
		end;
	end;
run;


*Import raw 2011-2020 E-4 city data from the finalized file, only from specified cell range;
proc import	out 		= e1_raw_city
			datafile 	= "&inpath.\E-4_2010-2020-Internet-Version.xlsx" 	/* REVISE INPUT FILE EACH YEAR */
			dbms 		= excel
			replace
			;
			sheet		= "Table 2 City County$";
			range		= "A1:L711";								/* REVISE DATA RANGE EACH YEAR */
run;
*Clean up the data a bit: keep Berkeley, Pasadena, and Long Beach, rename variables;
data e1_cities11 (keep = lhj year pop belongs_to_county);
	length LHJ belongs_to_county $15;
	set e1_raw_city;
	LHJ = Table_2__E_4_Population_Estimate;
	if lhj = 'Berkeley' then belongs_to_county = 'Alameda';
	else if lhj in('Long Beach','Pasadena') then belongs_to_county = 'Los Angeles';
	*create output records that associate the Excel columns with years;
	array years{*} f3--f12;		/* REVISE ARRAY END REFERENCE EACH YEAR */
	do i = 1 to dim(years);
		YEAR = 2011+i-1;
		POP = years{i};
		if 2011 <= year <= 2020 then do;		/* REVISE CURRENT YEAR VALUE EACH YEAR */
			if lhj in ('Berkeley','Long Beach','Pasadena') then do;
				output;
			end;
		end;
	end;
run;


*Import raw 2011-2020 E-4 county data from the finalized file, only from specified cell range;
proc import	out 		= e1_raw_county
			datafile 	= "&inpath.\E-4_2010-2020-Internet-Version.xlsx" 	/* REVISE INPUT FILE EACH YEAR */
			dbms 		= excel
			replace
			;
			sheet		= "Table 1 County State$";
			range		= "A1:L61";									/* REVISE DATA RANGE EACH YEAR */
run;
*Clean up the data a bit: keep Alameda, and Los Angeles, rename variables;
data e1_counties11(keep = lhj year pop);
	length LHJ $15;
	set e1_raw_county;
	LHJ = Table_1__E_4_Population_Estimate;
	*create output records that associate the Excel columns with years;
	array years{*} f3--f12;		/* REVISE ARRAY END REFERENCE EACH YEAR */
	do i = 1 to dim(years);
		YEAR = 2011+i-1;
		POP = years{i};
		if 2011 <= year <= 2020 then do;	/* REVISE CURRENT YEAR VALUE EACH YEAR */
			if lhj in('Alameda','Los Angeles') then do;
				output;
			end;
		end;
	end;
run;

* 2021-current E4 data for cities;
proc import	out 		= e4_raw_city
			datafile 	= "&inpath.\E-4_2022_InternetVersion.xlsx" 	/* REVISE INPUT FILE EACH YEAR */
			dbms 		= excel
			replace
			;
			sheet		= "Table 2 City County$";
			range		= "A1:D711";								/* REVISE DATA RANGE EACH YEAR */
run;

data e1_cities21 (keep = lhj year pop belongs_to_county);
	length LHJ belongs_to_county $15;
	set e4_raw_city;
	LHJ = Table_2__E_4_Population_Estimate;
	if lhj = 'Berkeley' then belongs_to_county = 'Alameda';
	else if lhj in('Long Beach','Pasadena') then belongs_to_county = 'Los Angeles';
	*create output records that associate the Excel columns with years;
	array years{*} f3--f4;		/* REVISE ARRAY END REFERENCE EACH YEAR */
	do i = 1 to dim(years);
		YEAR = 2021+i-1;
		POP = years{i};
		if 2021 <= year <= 2030 then do;		/* REVISE CURRENT YEAR VALUE EACH YEAR */
			if lhj in ('Berkeley','Long Beach','Pasadena') then do;
				output;
			end;
		end;
	end;
run;


* 2021-current E4 data for counties;
proc import	out 		= e4_raw_county
			datafile 	= "&inpath.\E-4_2022_InternetVersion.xlsx" 	/* REVISE INPUT FILE EACH YEAR */
			dbms 		= excel
			replace
			;
			sheet		= "Table 1 County State$";
			range		= "A1:D61";									/* REVISE DATA RANGE EACH YEAR */
run;

data e1_counties21(keep = lhj year pop);
	length LHJ $15;
	set e4_raw_county;
	LHJ = Table_1__E_4_Population_Estimate;
	*create output records that associate the Excel columns with years;
	array years{*} f3--f4;		/* REVISE ARRAY END REFERENCE EACH YEAR */
	do i = 1 to dim(years);
		YEAR = 2021+i-1;
		POP = years{i};
		if 2021 <= year <= 2030 then do;	/* REVISE CURRENT YEAR VALUE EACH YEAR */
			if lhj in('Alameda','Los Angeles') then do;
				output;
			end;
		end;
	end;
run;

* Merge 2010, 2011-2020, 2021-cy ;
data e1_cities;
	set e1_cities10 e1_cities11 e1_cities21;
run;
data e1_counties;
	set e1_counties10 e1_counties11 e1_counties21;
run;


*(Estimated E6 City Population) = (E4 City Population)*(E6 County Population) / (E4 County Population);
proc sql;
	create	table e6_cities_est as
	select	a.lhj, a.belongs_to_county, a.year, (a.pop/b.pop) as RATIO, c.pop*(a.pop/b.pop) as POP
	from	e1_cities as a
	INNER JOIN e1_counties as b
	on		a.belongs_to_county = b.lhj
	and		a.year = b.year
	INNER JOIN std.july1est_2010_cy_cnty as c
	on		b.lhj = c.lhj
	and		b.year = c.year
	;
quit;
data e6_HD_est;
	set e6_cities_est;
	if LHJ ="Berkeley" then LHJ = "Alameda HD";
	else if LHJ in ("Long Beach","Pasadena") then LHJ = "Los Angeles HD";
run;
proc sql;
	create table e6_HD_est2 as
	select LHJ, belongs_to_county, YEAR, sum(POP) as citypop
	from e6_HD_est
	group by LHJ, belongs_to_county, YEAR;
quit;
proc sql;
	create	table e6_HD_est3 as
	select	a.lhj, a.belongs_to_county, a.year, b.pop-a.citypop as POP
	from	e6_HD_est2 as a
	INNER JOIN std.july1est_2010_cy_cnty as b
	on		a.belongs_to_county = b.lhj
	and		a.year = b.year
	;
quit;


proc sql;
	create table std.July1est_2010_cy_all as
	select LHJ, YEAR, POP
	from std.July1est_2010_cy_cnty
	union
	select LHJ, YEAR, POP
	from e6_cities_est
	union
	select LHJ, YEAR, POP
	from e6_HD_est3
	;
quit;

* Combine all the July 1 files through the current year;
proc sql;
	create table all.July1est_1947_cy as
	select *
	from std.july1est_1947_2009_all
	union
	select * 
	from std.july1est_2010_cy_all
	;
quit;
