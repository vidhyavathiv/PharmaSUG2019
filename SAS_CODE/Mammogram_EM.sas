*-----------------------------------------------------------------------------*;
* Include Macros and Proto_FCMP files                                  		  *;
*-----------------------------------------------------------------------------*;
   %let root       = %str(C:\IMAGE_PROCESSING\);
   %let macro_root = %str(C:\\IMAGE_PROCESSING\\);
   %let dll_root   = %str(C:\IMAGE_PROCESSING\DLL_32\);
   
   %include "&root.SAS_CODE\Proto_Fcmp.sas";

*-----------------------------------------------------------------------------*;
* Define X and Y start and end points to define area inside window.    		  *;
* Define Wx and Wy start and end points to define the window border.          *;
*-----------------------------------------------------------------------------*;
	%let X_begin  = 271;
	%let X_finish = 299;
	%let Y_begin  = 191;
	%let Y_finish = 259;

    %let Wx_begin  = 270;
	%let Wx_finish = 300;
	%let Wy_begin  = 190;
	%let Wy_finish = 260;

*-----------------------------------------------------------------------------*;
* Use PROTO_FCMP and GETIMAGE macro to create Mammogram_In.csv file for  	  *;
* Mammogram_In.bmp. Use CHECK_ERRLOG to create global macro variables         *;
*-----------------------------------------------------------------------------*;

   %proto_fcmp(%str(&dll_root.ImageManipulation.dll),work);
   %getimage(work,"&macro_root.BMP\\Source\\Mammogram_In.bmp$","&macro_root.CSV_TXT\\Mammogram_In.csv$");

   %check_errlog();
   %put &last_col.;

*-----------------------------------------------------------------------------*;
* Input csv file into dataset Mammo_1. Define record length =  1000000 to     *;
* input long records. Input Cols as define using global macro LAST_COL        *;
*-----------------------------------------------------------------------------*;

   data Mammo_1 ;
 	   infile "&root.CSV_TXT\Mammogram_In.csv" lrecl=1000000 ;
	    input a1-&last_col.;

		count = _N_;
   run;

*-----------------------------------------------------------------------------*;
* Create window around the thick line using macros Wx and Wy begin and finish *;
*-----------------------------------------------------------------------------*;
   data Mammo_window;
     set Mammo_1;
		array window_ {*} a&Wx_begin. - a&Wx_finish.;
		if count in(&Wy_begin.,&Wy_finish.) then do;
			do i = 1 to dim(window_);
			  window_(i) = 1;
			end;
	    end;
		else if &Wy_begin. <= count <= &Wy_finish. then do; 
		   a&Wx_begin.  = 1;
		   a&Wx_finish. = 1;
        end;
   run;

*-----------------------------------------------------------------------------*;
* Output Interim image as Mammogram_window.bmp                                *;
*-----------------------------------------------------------------------------*;
   data _null_;
	  set  Mammo_window;
	    file "&root.CSV_TXT\Mammogram_window.txt" DELIMITER= ' ' lrecl=1000000 FLOWOVER;
	     put a1- &last_col.;
   run;

   %outImage(work,"&macro_root.BMP\\Source\\Mammogram_In.bmp$","&macro_root.CSV_TXT\\Mammogram_window.txt$","&macro_root.BMP\\Created\\Mammogram_window.bmp$");
	
*-----------------------------------------------------------------------------*;
* Set values which are eq 1 (white pixels) inside the window to missing(black)*;
* Output all values inside the window to Mammo_miss                           *;
*-----------------------------------------------------------------------------*;
   data Mammo_2;
     set Mammo_window;
       array one_2_miss {*} a&X_begin. - a&X_finish.;
          do i=1 to dim(one_2_miss);
	        if &Y_begin.<= count <= &Y_finish. then do;
		        if one_2_miss{i} = 1 then one_2_miss{i}=.;
	        end;
          end;
   run;
   
   data Mammo_miss;
     set Mammo_2;
        if &Y_begin. <= count <= &Y_finish. then output Mammo_miss;
      keep a&X_begin.-a&X_finish. count;
   run;

*-----------------------------------------------------------------------------*;
* Use Proc MI to randomly impute values to missing cells in Mammo_miss.       *;
* Obtain avergae of the imputation using Proc means. Rename imputed columns   *;
*-----------------------------------------------------------------------------*;
   proc mi data= Mammo_miss seed=300 simple nimpute=100 out=Mammo_Imp1;
     em itprint outem = outem_Mammo;   
     var a&X_begin.-a&X_finish.; 
     EM maxiter=500;
   run;

   proc means data=Mammo_Imp1;
     var a&X_begin.-a&X_finish.; 
     class count;
     output out=Mammo_ImpMean (where=(_STAT_= 'MEAN' & count > .));
   run;

   data Mammo_Imp2;
	set Mammo_ImpMean(drop=_TYPE_ _FREQ_ _STAT_);
	   array original {*} a&X_begin. - a&X_finish.;
	   array rename_  {*} Z&X_begin. - Z&X_finish.;
	      do i=1 to dim(original);
		     rename_{i}= original{i};
	    end;
	   drop a&X_begin. - a&X_finish. i;
	   rename Count = ImpMean_count;
	run;

*-----------------------------------------------------------------------------*;
* Force all pixel values in the window to be missing in the original dataset  *;
*-----------------------------------------------------------------------------*;

    data Mammo_nmiss;
      set Mammo_1;
        array convert_missing {*} a&X_begin. - a&X_finish.;
           do i=1 to dim(convert_missing);
	          if &Y_begin.<=count<=&Y_finish. then do;
       		     convert_missing{i}=.;
	          end;
           end;
    run;

*-----------------------------------------------------------------------------*;
* Merge Mammo_nmiss and Mammo_Imp2 by count. Replace all missing values in    *;
* Mammo_nmiss with mean of imputed values from  Mammo_Imp2                    *;     
*-----------------------------------------------------------------------------*;
	
    proc sql;
       create table Mammo_3 as select *
	   from Mammo_nmiss a left join Mammo_Imp2 b
	   on a.Count = b.ImpMean_count;
    quit;

    data Mammo_out (drop=count);
      set Mammo_3;
        array final  {*} a&X_begin. - a&X_finish.;
        array Imputed{*} Z&X_begin. - Z&X_finish.;
           do i=1 to dim(final);
	          if &Y_begin.<= count <= &Y_finish. then do;
		          if final{i} = . then final{i} = Imputed{i};
	          end;
           end;
           drop  Z&X_begin. - z&X_finish. i ImpMean_count;
    run;

*-----------------------------------------------------------------------------*;
* Output Mammo_out into txt file. Use OUTIMAGE macro to create Mammogram_final*;
*-----------------------------------------------------------------------------*;
   data _null_;
	 set  Mammo_out  ;
	    file "&root.CSV_TXT\Mammogram_out.txt" DELIMITER= ' ' lrecl=1000000 FLOWOVER;
	    put a1- &last_col.;
   run;

   %outImage(work,"&macro_root.BMP\\Source\\Mammogram_In.bmp$","&macro_root.CSV_TXT\\Mammogram_out.txt$","&macro_root.BMP\\Created\\Mammogram_out.bmp$");
	
	



