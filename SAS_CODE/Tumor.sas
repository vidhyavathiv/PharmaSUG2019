*-----------------------------------------------------------------------------*;
* Include Macros and Proto_FCMP files                                  		  *;
*-----------------------------------------------------------------------------*;
   %let root       = %str(C:\IMAGE_PROCESSING\);
   %let macro_root = %str(C:\\IMAGE_PROCESSING\\);
   %let dll_root   = %str(C:\IMAGE_PROCESSING\DLL_32\);
   
   %include "&root.SAS_CODE\Proto_Fcmp.sas";
   
*-----------------------------------------------------------------------------*;
* Macro 		: SET_DATASETS(count_datasets)                                *;
* Parameters	: count_datasets                                              *;
* Result		: Histogram_1                                                 *;
* Description	: concatenate datasets determined in the "do" condition       *; 
*            	: onto Histogram_1.                                           *;
*-----------------------------------------------------------------------------*;
 
  %macro set_datasets(count_datasets);
    %do i = 2 %to &count_datasets.;
      data Histogram_1;
         set Histogram_1 a&i.;
      run;
    %end;
  %mend set_datasets;

*-----------------------------------------------------------------------------*;
* Macro 		: stacks(datain,varnum_val)                                   *;
* Parameters	: Input dataset datain) and NVAR (varnum_val)                 *;  
* Result		: Histogram_1                                                 *;
* Description	: Creates Histogram_1 with 3 cols = Intensity, ord,col_ord    *;
*-----------------------------------------------------------------------------*;
  %macro stacks(Indata,varnum_val);

    %do i=1 %to &varnum_val.;
	    data a&i.(keep = intensity row_order col_order Colnumeric);
          set &Indata.;
		  intensity=a&i.;
		  col_order='a'||strip(put(&i.,best.));
		  Colnumeric = &i.;
	    run;
     %end;

	 data Histogram_1;
	    set a1;
	 run;

	 %set_datasets(&varnum_val.);
  %mend stacks;
*-----------------------------------------------------------------------------*;
* Call Macro %proto_fcmp() to create and store fcmp and proto dataset in work *;
* Use %getimage() to create csv file using wrapper function                   *;
*-----------------------------------------------------------------------------*;
  %proto_fcmp(%str(&dll_root.ImageManipulation.dll),work);
  %getimage(work,"&macro_root.BMP\\Source\\Tumor_In.bmp$","&macro_root.CSV_TXT\\Tumor_In.csv$");

*-----------------------------------------------------------------------------*;
* Use %check_errlog() to determine last_col and no_cols value using Error.log *;
* created in current directory                                                *;
*-----------------------------------------------------------------------------*;
  %check_errlog();

*-----------------------------------------------------------------------------*;
* Create dataset from csv file. Sort in descending order of _N_               *;
*-----------------------------------------------------------------------------*;
  data Input_Histogram;
    infile "&macro_root.CSV_TXT\\Tumor_In.csv" dlm = ' ' lrecl=100000 ;
    input a1- &last_col.;
	   row_order = _N_;
  run;

  proc sort data = Input_Histogram;
	by descending row_order;
  run;

*-----------------------------------------------------------------------------*;
* Concatenate all columns to obtain Intensity                                 *;
* Keep only required datasets in the work library                             *; 
*-----------------------------------------------------------------------------*;	
  %stacks(Input_Histogram, &no_cols.);
     
  proc datasets library=work;
     save Input_Histogram Histogram_1 Proto FCMP;
  quit;

*-----------------------------------------------------------------------------*;
* Linear Transformation                                                       *;
*-----------------------------------------------------------------------------*;	

  proc univariate data=Histogram_1;
	var intensity;
	 histogram; 
	 cdfplot ;
  run;

  proc freq data=Histogram_1 ;
	table intensity;
	 ods output OneWayFreqs = Histogram_2;
  run;

  data Histogram_3;
     set Histogram_2;
	  cdf=CumPercent/100;
		keep intensity cdf;
  run;

  proc sort data=Histogram_1;
	by intensity;
  run;

  data Transform;
	merge Histogram_1 Histogram_3;
	  by intensity;
  run;

  data LT_1 (keep=new_intensity row_order col_order Colnumeric);
	set Transform;;
	  new_intensity=cdf;
  run;

  proc univariate data=LT_1;
	 var new_intensity;
	  histogram; 
	  cdfplot ;
  run;	
   
*-----------------------------------------------------------------------------*;
* Recreate the original dataset using row_order (_N_) and col_order variables *;
*-----------------------------------------------------------------------------*;
  proc sort data=LT_1 out=LT_2;
	by row_order Colnumeric col_order;
  run;

  proc transpose data=LT_2(drop = Colnumeric) out= LT_3(drop = _NAME_);
	by row_order;
	id  col_order;
  run;

*-----------------------------------------------------------------------------*;
* Sort by ascending _N_ and output dataset to text file                       *;
* Use %OutImage() to create output image using wrapper function               *;
*-----------------------------------------------------------------------------*;
  proc sort data = LT_3;
	by row_order;
  run;
	
  data _null_;
	set LT_3;
 	  file "&root.CSV_TXT\Tumor_LT.txt" dlm = ' ' lrecl=100000 ;
	   put a1- &last_col.;
  run;

  %OutImage(work,"&macro_root.BMP\\Source\\Tumor_In.bmp$","&macro_root.CSV_TXT\\Tumor_LT.txt$","&macro_root.BMP\\Created\\Tumor_LT.bmp$");

*-----------------------------------------------------------------------------*;
* Pixel based transformation Alpha = 5 and Threshold = 0.5                    *;
*-----------------------------------------------------------------------------*;

  %let alpha=5;
  data PT_1 (keep=new_intensity row_order col_order);
	set Transform;
	    if intensity<=0.5 then do;
		     new_intensity=0.5*(intensity/.5)**&alpha.;
		end;
		else do;
		     new_intensity=1- 0.5*((1-intensity)/.5)**&alpha.;
		end;
   run;
	  
*-----------------------------------------------------------------------------*;
* Recreate the original dataset using row_order (_N_) and col_order variables *;
*-----------------------------------------------------------------------------*;
   proc sort data=PT_1 out=PT_2;
	 by descending row_order col_order;
   run;

   proc transpose data=PT_2 out= PT_3(drop = _NAME_);
	 by descending row_order;
	 id col_order;
   run;

*-----------------------------------------------------------------------------*;
* Sort by ascending _N_ and output dataset to text file                       *;
* Use %OutImage() to create output image using wrapper function               *;
*-----------------------------------------------------------------------------*;
   proc sort data = PT_3; 
    by row_order;
   run;
	
   data _null_;
	 set PT_3; 
 	  file "&root.CSV_TXT\Tumor_PT.txt" dlm = ' ' lrecl=100000 ;
	  put a1- &last_col.;
   run;

   %OutImage(work,"&macro_root.BMP\\Source\\Tumor_In.bmp$","&macro_root.CSV_TXT\\Tumor_PT.txt$","&macro_root.BMP\\Created\\Tumor_PT.bmp$");



