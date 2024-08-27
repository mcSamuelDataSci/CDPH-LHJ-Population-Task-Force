
libname chis "P:\Project Files\David Crow\Data";
libname output "P:\Project Files\David Crow\SOGI\output";

options locale=en_US symbolgen;

****************************************************
*CREATE POOLED DATA SET
****************************************************;

*Read in Data and restrict to select variables of interest;
%let startyr = 14;
%let endyr = 22;

%macro read(startyr, endyr);
	%do i=&startyr. %to &endyr;

	data sogi&i.;
		set chis.adult&i.;

		year = 20&i.;
		drop KIDS1ST;
	run;

	%end;
%mend read;
%read(&startyr, &endyr)



/*Combine the data sets*/
data sogi;
	set sogi&startyr. - sogi&endyr.;
run;


/*Create and rename variables*/
proc format;
	value sex				0='Male'
							1='Female';

	value trans				0='Cisgender'
							1='Transgender';

	value sexualorientation 0='Heterosexual'
							1='Gay, lesbian, or homosexual'
							2='Bisexual'
							3='Asexual/Celibate/Other';

	value race 				0='Other or multiple'
							1='Hispanic'
							2='White, NH'
							3='Black, NH'
							4='Native American, NH'
							5='Asian, NH';

	value age 				1='18-25'
							2='26-35'
							3='36-45'
							4='46-55'
							5='56-65'
							6='66-75'
							7='75+';

	value yesno				0='No'
							1='Yes';

	value county
		1 = "Alameda"
		2 = "Alpine"
		3 = "Amador"
		4 = "Butte"
		5 = "Calaveras"
		6 = "Colusa"
		7 = "Contra Costa"
		8 = "Del Norte"
		9 = "El Dorado"
		10 = "Fresno"
		11 = "Glenn"
		12 = "Humboldt"
		13 = "Imperial"
		14 = "Inyo"
		15 = "Kern"
		16 = "Kings"
		17 = "Lake"
		18 = "Lassen"
		19 = "Los Angeles"
		20 = "Madera"
		21 = "Marin"
		22 = "Mariposa"
		23 = "Mendocino"
		24 = "Merced"
		25 = "Modoc"
		26 = "Mono"
		27 = "Monterey"
		28 = "Napa"
		29 = "Nevada"
		30 = "Orange"
		31 = "Placer"
		32 = "Plumas"
		33 = "Riverside"
		34 = "Sacramento"
		35 = "San Benito"
		36 = "San Bernardino"
		37 = "San Diego"
		38 = "San Francisco"
		39 = "San Joaquin"
		40 = "San Luis Obispo"
		41 = "San Mateo"
		42 = "Santa Barbara"
		43 = "Santa Clara"
		44 = "Santa Cruz"
		45 = "Shasta"
		46 = "Sierra"
		47 = "Siskiyhou"
		48 = "Solano"
		49 = "Sonoma"
		50 = "Stanislaus"
		51 = "Sutter"
		52 = "Tehama"
		53 = "Trinity"
		54 = "Tulare"
		55 = "Tuolume"
		56 = "Ventura"
		57 = "Yolo"
		58 = "Yuba";
run;


data sogi2 (keep = TRANSGEND2 trans AD46 AD46B sexualorientation gay WRKST SRAGE age OMBSRR_P1 year SRSEX sex race OMBSRREO FIPS_CNT county zip tract tsvarstr 
					tsvrunit rakedw0 rakedw0_rs rakedw1-rakedw80 n);

	set sogi;

	/*SOGI*/
		/*Sex*/
		If SRSEX=1 then sex=0;
			else if SRSEX=2 then sex=1;
			else if SRSEX= -7 then sex=.;

		/*Gender Identity*/
		If TRANSGEND2=-2 then trans=.;
			else if TRANSGEND2=1 then trans=0;
			else if TRANSGEND2=2 then trans=1;

		/*Sexual orientation*/
		If (AD46=1 or AD46B=1 or AD46C=1) then sexualorientation=0;
			else if (AD46=2 or AD46B=2 or AD46C=2) then sexualorientation=1;
			else if (AD46=3 or AD46B=3 or AD46C=3) then sexualorientation=2;
			else if (AD46 in (4,5) or AD46B in (4,5) or AD46C in (4,5,6)) then sexualorientation=3;
			else if (AD46 in (-1,-2) or AD46B in (-1,-2) or AD46C in (-1,-2)) then sexualorientation=.;

		/*Gay man*/
		If (AD46=2 or AD46B=2 or AD46C=2) and SRSEX=1 then gay=1;
			else if (AD46 in (-1,-2) or AD46B in (-1,-2) or AD46C in (-1,-2) or 
				SRSEX=-7) then gay=.;
			else gay=0;
			
	/*Stratifiers*/
		/*Race*/
		If OMBSRR_P1=1 then race=1;
			else if OMBSRR_P1=2 then race=2;
			else if OMBSRR_P1=3 then race=3;
			else if OMBSRR_P1=4 then race=4;
			else if OMBSRR_P1=5 then race=5;
			else if OMBSRR_P1=6 then race=0;

		/*Age Categories*/	
		If SRAGE >=18 and SRAGE <=25 then age=1;
			else if SRAGE >=26 and SRAGE <=35 then age=2;
			else if SRAGE >=36 and SRAGE <=45 then age=3;
			else if SRAGE >=46 and SRAGE <=55 then age=4;
			else if SRAGE >=56 and SRAGE <=65 then age=5;
			else if SRAGE >=66 and SRAGE <=75 then age=6;
			else if SRAGE >75 then age=7;

	/*Geography*/
		n = 1;
		county = SRCNTY;
		zip = BESTZIP;
		tract = UR_TRACT6;
	
	/*Rescaled Expansion Factor*/
		rakedw0_rs = rakedw0 / 8;

		label sex='Sex';
		label trans='Gender identity';
		label sexualorientation='Sexual orientation';
		label age='Age category';
		label race='Primary race or ethncity';
		label rakedw0_rs='Rescaled expansion factor';

	format sex sex. trans trans. sexualorientation sexualorientation. race race. age age. county county.;	
run;


/*Replicate Weights for Pooled Dataset Using SAS Macro*/
%inc "P:\Project Files\David Crow\CHIS Documentation for CDPH_062023\Sample Code\Pooling CHIS Data\CHISPOOLING.sas";
%CHISPOOLING(DATAIN = sogi2, DATAOUT = sogi2, YEARLIST = 2014 2015 2016 2017 2018 2019 2020 2021 2022, PREFIX = FNWGT);


proc contents data=sogi2;
run;


/*Frequencies*/
proc freq data=sogi2;
	tables sexualorientation*year / norow nopercent;
run;


/*Sexual Orientation Statewide and by County*/
/*Jackknife*/
%let start_time = %sysfunc(datetime());
ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_soxcnty.csv" ;
ods output CrossTabs = sogi_soxcnty;
proc surveyfreq data=sogi2 varmethod=jackknife;
	weight fnwgt0;
	repweights fnwgt1-fnwgt&repn. / jkcoefs=.9999;
	table sexualorientation / cl clwt;
	table sexualorientation*county / nocellpct col cl clwt;
	format county county.;
run;
ods csv close;
%let end_time = %sysfunc(datetime());
%let run_time = %sysevalf((&end_time - &start_time));
%put "Runtime for jackknife estimator is:  &run_time";

ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_soxyear.csv" ;
ods output CrossTabs = sogi_soxyear;
proc surveyfreq data=sogi2 varmethod=jackknife;
	weight rakedw0;
	repweights rakedw1-rakedw80 / jkcoefs=.9999;
	table sexualorientation*year / nocellpct col cl clwt;
	format county county.;
run;
ods csv close;




/*Sexual Orientation Statewide by County by Sex*/
proc sort data=sogi2;
	by sex;
run;


ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_soxcntyxsex.csv" ;
ods output CrossTabs = sogi_soxcntyxsex;
proc surveyfreq data=sogi2 varmethod=jackknife;
	weight fnwgt0;
	repweights fnwgt1-fnwgt&repn. / jkcoefs=.9999;
	table sexualorientation / cl clwt;
	table sexualorientation*county /nocellpct col cl clwt;
	by sex;
	format county county.;
run;

ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_soxyearxsex.csv" ;
ods output CrossTabs = sogi_soxyearxsex;
proc surveyfreq data=sogi2 varmethod=jackknife;
	weight rakedw0;
	repweights rakedw1-rakedw80 / jkcoefs=.9999;
	table sexualorientation*year / nocellpct col cl clwt;
	by sex;
	format county county.;
run;



/*Jackknife vs. Taylor Series*/
/*Jackknife
%let start_time = %sysfunc(datetime());
proc surveyfreq data=sogi2 varmethod=jackknife;
	weight fnwgt0;
	repweights fnwgt1-fnwgt&repn. / jkcoefs=.9999;
	table sexualorientation / cl clwt;
	table year*sexualorientation / cl clwt;
	where 2014 <= year <= 2020; 
run;
%let end_time = %sysfunc(datetime());
%let run_time_jk = %sysevalf((&end_time - &start_time));

%put "Runtime for jackknife estimator is:  &run_time_jk";


/*Taylor Series
%let start_time = %sysfunc(datetime());
proc surveyfreq data=sogi2 varmethod=taylor;
	strata tsvarstr;
	cluster tsvrunit;
	weight rakedw0_rs;
	table sexualorientation / cl clwt;
	table year*sexualorientation / cl clwt;
run;
%let end_time = %sysfunc(datetime());
%let run_time_ts = %sysevalf((&end_time - &start_time));

%put "Runtime for Taylor series linearization is:  &run_time_ts";
*/


*****************************************
*Gay Men
*****************************************;

data sogi2;
	set sogi2;
	where county ne -1;
run;

proc freq data=sogi2;
	table county*year / nopercent norow nocol;
run;


proc freq data=sogi2;
	table year*gay / nopercent nocol;
run;


/*Direct Estimator*/
/*Direct calculation from counts*/
proc sql;
	select county,
		sum(gay) as gay,
		sum(n) as total,
		sum(gay)/sum(n) as per
	from sogi2
	group by county;
quit;

/*Using PROC LOGISTIC*/
ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_direct.csv" ;
proc logistic data=sogi2;
	class county;
	model gay(event = "1") = county / cl link=logit;
	output out=probs predicted=phat lower=phat_cil upper=phat_uil;
	format county county.;
	ods trace on;
run;

proc sql;
	create table direct_est as
	select distinct county,
		phat,
		phat_cil,
		phat_uil
	from probs
	group by county;
quit;

proc export data=work.direct_est
	outfile="P:\Project Files\David Crow\SOGI\output\direct_est.csv" 
	dbms = csv
	replace;
run; 

proc means data=sogi2 sum n mean lclm uclm;
	class county;
	var gay;
	format county county. sum 8.0;
	ods trace on;
	ods output ParameterEstimates = f_int;
run;


/*Using PROC SURVEYLOGISTIC*/
/*Weighted Direct Estimates*/
ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_directw.csv" ;
proc surveylogistic data=sogi2;
	weight fnwgt0;
	repweights fnwgt1-fnwgt&repn. / jkcoefs=.9999;
	class county;
	model gay(event = "1") = county / link=logit;
	output out=probs_w predicted=phat_w lower=phat_cil_w upper=phat_uil_w;
	format county county.;
	ods trace on;
run;


proc sql;
	create table direct_est_w as
	select distinct county,
		phat_w,
		phat_cil_w,
		phat_uil_w
	from probs_w
	group by county;
quit;

proc export data=work.direct_est_w
	outfile="P:\Project Files\David Crow\SOGI\output\direct_est_w.csv" 
	dbms = csv
	replace;
run; 





/*Indirect Estimator:  Random Intercepts only*/
/*with pred output*/
ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_indirect.csv" ;
proc glimmix data=sogi2 itdetails method=quad;
	class county;
	model gay(event = "1") = / solution cl link=logit dist=binary;
	random intercept / subject=county solution cl g;
	output out=indirect_est pred(blup ilink) = rints stderr(blup ilink) = rmse_blup lcl(ilink)=cil_rint ucl(ilink)=uil_rint;
	ods trace on;
run;

proc sql;
	create table indirect_est as
	select distinct county,
		rints,
		cil_rint,
		uil_rint
	from indirect_est
	group by county;
quit;

proc export data=work.indirect_est
	outfile="P:\Project Files\David Crow\SOGI\output\indirect_est2.csv" 
	dbms = csv
	replace;
run; 


/*Indirect Estimator:  Random Intercepts + Fixed Predictors*/
ods csv file="P:\Project Files\David Crow\SOGI\output\sogi_indirect_yr.csv" ;
proc glimmix data=sogi2 itdetails method=quad;
	class county;
	model gay(event = "1") = year / solution cl link=logit dist=binary;
	random intercept / subject=county solution cl g;
	output out=indirect_est2 pred(blup ilink) = rints_fe stderr(blup ilink) = rmse_fe lcl(blup ilink)=cil_rintfe ucl(blup ilink)=uil_rintfe;
	ods trace on;
run;

proc sql;
	create table indirect_est2 as
	select distinct county,
		year,
		rints_fe,
		cil_rintfe,
		uil_rintfe
	from indirect_est2
	group by county;
quit;

proc export data=work.indirect_est2
	outfile="P:\Project Files\David Crow\SOGI\output\indirect_est_yr.csv" 
	dbms = csv
	replace;
run; 

