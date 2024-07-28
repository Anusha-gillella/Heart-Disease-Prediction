%WEB_DROP_TABLE(WORK.TEST);

FILENAME REFFILE "/home/u63665225/Project/heart.csv";

PROC IMPORT DATAFILE=REFFILE
		DBMS=CSV
		OUT=WORK.TEST;
		GETNAMES=YES;
RUN;



PROC CONTENTS DATA=WORK.TEST; 
RUN;

%web_open_table(WORK.TEST);


***************** Heart Disease Prediction**************;

** 1. Univariate Analysis Categorical Variables ****;

%MACRO MACRO_UVA_CV(DATASET_NAME, VARIABLE_NAME, TITLE_1, TITLE_2);
	PROC FREQ DATA=&DATASET_NAME;
		TABLE &VARIABLE_NAME;
	RUN;

ODS GRAPHICS / RESET WIDTH=4.0 IN HEIGHT=3.0 IN IMAGEMAP;

	PROC SGPLOT DATA=&DATASET_NAME;
		VBAR &VARIABLE_NAME;
		TITLE &TITLE_1;
		TITLE2 &TITLE_2;
	RUN;

%MEND MACRO_UVA_CV;

%MACRO_UVA_CV(WORK.TEST, Sex, 
				'Categorical Variables - Univariate Analysis',
				'on Sex (Gender)');
					 

%MACRO_UVA_CV(WORK.TEST, cp, 
				'Categorical Variables - Univariate Analysis',
				'on cp (Chest Pain Type)');
					 

%MACRO_UVA_CV(WORK.TEST, fbs, 
				'Categorical Variables - Univariate Analysis',
				'on fbs (Fasting Blood Sugar)');


%MACRO_UVA_CV(WORK.TEST, restecg, 
				'Categorical Variables - Univariate Analysis', 
				'on restecg (Resting Electrocardiographic Results)');


%MACRO_UVA_CV(WORK.TEST, exang, 
				'Categorical Variables - Univariate Analysis', 
				'on exang (Exercise Induced Angina)');


%MACRO_UVA_CV(WORK.TEST, slope, 
				'Categorical Variables - Univariate Analysis', 
				'on slope (Slope of the Peak Exercise)');


%MACRO_UVA_CV(WORK.TEST, ca, 
				'Categorical Variables - Univariate Analysis', 
				'on ca (Number of Major Vessels)');


%MACRO_UVA_CV(WORK.TEST, thal, 
				'Categorical Variables - Univariate Analysis', 
				'on thal');


%MACRO_UVA_CV(WORK.TEST, target, 
				'Categorical Variables - Univariate Analysis', 
				'on target (Heart Diseases Status)');			
					 
/***** 2. SAS Macro Numerical Variables Univariate Analysis *******/
%MACRO MACRO_UVA_NV(DATASET_NAME, VARIABLE_NAME, TITLE_1, TITLE_2);

	PROC MEANS DATA=&DATASET_NAME N NMISS MIN MAX MEAN MEDIAN STD;
		VAR &VARIABLE_NAME;
		TITLE &TITLE_1;
		TITLE2 &TITLE_2;
	RUN;
	
ODS GRAPHICS / RESET WIDTH=4.0 IN HEIGHT=3.0 IN IMAGEMAP;

	PROC SGPLOT DATA= &DATASET_NAME;
		HISTOGRAM &VARIABLE_NAME;
	RUN;

%MEND MACRO_UVA_NV;


%MACRO_UVA_NV(WORK.TEST, age, 
		'Numerical Variables - Univariate Analysis', 
		'on age');


%MACRO_UVA_NV(WORK.TEST, trestbps, 
		'Numerical Variables - Univariate Analysis', 
		'on trestbps');


%MACRO_UVA_NV(WORK.TEST, chol, 
		'Numerical Variables - Univariate Analysis', 
		'on chol');


%MACRO_UVA_NV(WORK.TEST, thalach, 
		'Numerical Variables - Univariate Analysis', 
		'on thalach');


%MACRO_UVA_NV(WORK.TEST, oldpeak, 
		'Numerical Variables - Univariate Analysis', 
		'on oldpeak');


/******* 3. Dataset Pre-processing*******/;

/* 3.1 Addding new columns For 'CP', 'Thal', 'Slope' and set their initial values */
/**** Dropping Variables ****/

DATA WORK.Test1 (drop= cp thal slope);
    SET WORK.Test;
    LENGTH cp_0 cp_1 cp_2 cp_3 
    		thal_0 thal_1 thal_2 thal_3 
    		slope_0 slope_1 slope_2 $1;
  /**** CP***********/  		
	cp_0 = "0";
    cp_1 = "0";
    cp_2 = "0";
    cp_3 = "0";

	    IF cp = "0" THEN cp_0 = "1";
	    ELSE IF cp = "1" THEN cp_1 = "1";
	    ELSE IF cp = "2" THEN cp_2 = "1";
	    ELSE IF cp = "3" THEN cp_3 = "1";
    
     /**** Thal ***********/ 
    thal_0 = "0";
    thal_1 = "0";
    thal_2 = "0";
    thal_3 = "0";

   
	    IF thal = "0" THEN thal_0 = "1";
	    ELSE IF thal = "1" THEN thal_1 = "1";
	    ELSE IF thal = "2" THEN thal_2 = "1";
	    ELSE IF thal = "3" THEN thal_3 = "1";

    /**** Slope ***********/ 
    slope_0 = "0";
    slope_1 = "0";
    slope_2 = "0";

   
	    IF slope = "0" THEN slope_0 = "1";
	    ELSE IF slope = "1" THEN slope_1 = "1";
	    ELSE IF slope = "2" THEN slope_2 = "1";
RUN;


ODS Graphics On / Width=1000  ImageMap=on;

Proc corr data = WORK.Test1 plots(MAXPOINTS=10000)= matrix(Histogram);
	var _numeric_;
run;

Ods Graphics off;


/******3.2 Splitting Dataset ******/
/*** Using PROC SURVEYSELECT to Specify Train Test Ratio Split */

PROC SURVEYSELECT DATA=WORK.Test1 RATE=0.8 
			OUT=Test1_Select 
			OUTALL 
			METHOD=SRS;
RUN;


DATA TEST_TRAIN (DROP=Selected) 
		TEST_TEST (DROP=Selected);
	SET Test1_Select;

	IF Selected="1" THEN
		OUTPUT TEST_TRAIN;
	ELSE
		OUTPUT TEST_TEST;
RUN;


/******** 3.3 Prepare Test Set *****/

DATA WORK.TEST_TEST;
	SET WORK.TEST_TEST;

	IF target="1" THEN target=.;
	ELSE target=.;
RUN;



/********** 4. Building Logistic Regression Model *******/
/* ======================================================== */

PROC LOGISTIC DATA=WORK.TEST_TRAIN
		OUTMODEL=WORK.TEST_TRAIN_LRMODEL;
	CLASS sex cp_0 cp_1 cp_2 cp_3 fbs restecg exang ca thal_0 thal_1 thal_2 thal_3 slope_0 slope_1 slope_2;
	MODEL target=
	age sex cp_0 cp_1 cp_2 cp_3 trestbps chol fbs restecg thalach exang oldpeak slope_0 slope_1 slope_2 ca thal_0 thal_1 thal_2 thal_3;
	OUTPUT OUT=WORK.TEST_TRAIN_LRMODEL_OUTPUT P=PRED_PROB;
RUN;

/*  Probability in Training */
PROC SQL;
	SELECT * FROM WORK.TEST_TRAIN_LRMODEL_OUTPUT;
QUIT;



/*  Prediction on Test */

PROC LOGISTIC INMODEL = WORK.TEST_TRAIN_LRMODEL;
		SCORE DATA = WORK.TEST_TEST
		OUT = WORK.TEST_PREDICTIONS;
QUIT;



/* Display Predictions */

PROC SQL;
	SELECT * FROM WORK.TEST_PREDICTIONS;
QUIT;



/* 5. Output Delivery System (ODS) */
/* ======================================================== */

/*  Locate the Output */

PROC DATASETS LIBRARY=WORK MEMTYPE=DATA;
	RUN;

/* Generate Output */

ODS HTML CLOSE;
ODS PDF CLOSE;
ODS RTF CLOSE;
	
	ODS PDF 
		FILE ='/home/u63665225/Project/Heart_Disease_Prediction_Report.pdf';
	ODS RTF 
		FILE = '/home/u63665225/Project/Heart_Disease_Prediction_Report.rtf';
		
	OPTIONS NOBYLINE NODATE;
	OPTIONS ORIENTATION = REVERSELANDSCAPE;
	TITLE 'Heart Disaease Prediction';
	
	PROC PRINT DATA=WORK.Test1 (OBS=10);
    VAR _ALL_;
RUN;

ODS PDF CLOSE;
ODS RTF CLOSE;

PROC REPORT DATA=WORK.TEST_PREDICTIONS NOWINDOWS;
	FOOTNOTE '---- End of Report // Report by @Anusha ----';
RUN;

OPTIONS BYLINE;

















