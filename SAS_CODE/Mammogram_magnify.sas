*-----------------------------------------------------------------------------*;
* Create global macro values                                         		  *;
*-----------------------------------------------------------------------------*;
   %let root       = %str(C:\IMAGE_PROCESSING\);
   %let macro_root = %str(C:\\IMAGE_PROCESSING\\);
   %let dll_root   = %str(C:\IMAGE_PROCESSING\DLL_32\);
   
   %include "&root.SAS_CODE\Proto_Fcmp.sas";

*-----------------------------------------------------------------------------*;
* Define X and Y start and end points to define the window around RoI  		  *;
*-----------------------------------------------------------------------------*;
    %let Wx_begin  = 240;
	%let Wx_finish = 320;
	%let Wy_begin  = 260;
	%let Wy_finish = 333;

*-----------------------------------------------------------------------------*;
* Use PROTO_FCMP and GETIMAGE macro to create Mammogram_src.csv file from  	  *;
* Mammogram_src.bmp. Use CHECK_ERRLOG to create  macro variables (last_col)   *;
*-----------------------------------------------------------------------------*;

   %proto_fcmp(%str(&dll_root.ImageManipulation.dll),work);
   %getimage(work,"&macro_root.BMP\\Source\\Mammogram_src.bmp$","&macro_root.CSV_TXT\\Mammogram_src.csv$");

   %check_errlog();
   %put &last_col.;

*-----------------------------------------------------------------------------*;
* Input csv file into dataset Mammo_1. Define record length =  1000000 to     *;
* input long records. Input Cols from a1 to &last_col.                        *;
*-----------------------------------------------------------------------------*;

   data Mammo_1 ;
 	   infile "&root.CSV_TXT\Mammogram_src.csv" lrecl=1000000 ;
	    input a1-&last_col.;

		count = _N_;
   run;

*-----------------------------------------------------------------------------*;
* Set cells as 1 to define window around the cyst using macro variables       *;
* Wx_begin,Wx_finish, Wy_begin and Wy_finish.                                 *;
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
* Output Interim dataset Mammo_window as Mammogram_cyst.bmp image             *;
*-----------------------------------------------------------------------------*;
   data _null_;
	  set  Mammo_window;
	    file "&root.CSV_TXT\Mammogram_cyst.txt" DELIMITER= ' ' lrecl=1000000 FLOWOVER;
	     put a1- &last_col.;
   run;

   %outImage(work,"&macro_root.BMP\\Source\\Mammogram_src.bmp$","&macro_root.CSV_TXT\\Mammogram_cyst.txt$","&macro_root.BMP\\Created\\Mammogram_cyst.bmp$");

*-----------------------------------------------------------------------------*;
* Drop count variable and Use proc IML to repeat each variable 5 times to     *;
* create a 5x magnification                                                   *;
*-----------------------------------------------------------------------------*;
  data Mammo_1;
    set Mammo_1;
	 drop count;
  run;

  proc IML;
    use  Mammo_1 ;
	read all var _NUM_ into Mammo_5xi;
	Mammo_5x = REPEAT(Mammo_5xi,1,5);

	create Mammo_append from Mammo_5x;
	append from Mammo_5x;
    close Mammo_append;
  quit;

*-----------------------------------------------------------------------------*;
* As 5 repeated datasets have been appened. Use below method to bring similar *;
* cells together.                                                             *;
*-----------------------------------------------------------------------------*;
  data Mammo_append (drop=i);
    set Mammo_append;
     do i=1 to 5;
       output;
     end;
  run;

  data Mammo_cells(drop=COL1 - COL2560);
     set Mammo_append;
        array original_ {*} COL1 - COL2560;
        array Magnify_  {*} a1 - a2560;

           do i=0 to 2559;
             quotient=int(i/5);
                Magnify_{i+1}=original_{512*(i-5*quotient)+(quotient+1)};
           end;
		  
   run;

   data Mammo_cells1; 
    set Mammo_cells;
	   count = _N_;
   run;
*-----------------------------------------------------------------------------*;
* Mammo_final keeps variables which define the cyst                           *;
* Output dataset to Mammogram_magnify text and using macro, output to bmp     *;
*-----------------------------------------------------------------------------*;
   data Mammo_final;
	 set Mammo_cells1;
		where 1175 < count <= 1755;
		keep a1094 - a1605;
   run;

  data _null_;
     set Mammo_final;
       file "&root.CSV_TXT\Mammogram_magnify.txt" DELIMITER= ' ' lrecl=1000000 FLOWOVER;
        put a1094 - a1605;
  run; 

  %outImage(work,"&macro_root.BMP\\Source\\Mammogram_src.bmp$","&macro_root.CSV_TXT\\Mammogram_magnify.txt$","&macro_root.BMP\\Created\\Mammogram_magnify.bmp$");
 
*-----------------------------------------------------------------------------*;
* For Bilineal Interpolation - set every 5 rows = .                           *;
*-----------------------------------------------------------------------------*;
  
  data mammo_mrow;
    set mammo_1;
	  do ct= 1 to 5;
		output;
	  end;
  run;
  
  data mammo_mrow;
     set mammo_mrow;
       array a{*} a1-a512;
        do i=1 to dim(a);
	      if ct ne 1 then a{i}=.;
     end;
  run;

  data mammo_2;
    set mammo_mrow;
       array a {*} a1-a512;
       array b {*} b1-b2560;
        do i=1 to 512;
		  b{5*i-4}=a{i};
        end;
     drop a1 - a512 ct i;
  run;

  data mammo_3;
     set mammo_2;
      count=_n_;
  run;

*-----------------------------------------------------------------------------*;
* Use expand for linear interpolation                                       *;
*-----------------------------------------------------------------------------*;
  proc expand data=mammo_3 out= Mammo_Int1;
	convert b1 - b2560/method=join;
	id count;
  run;

*-----------------------------------------------------------------------------*;
* Tranpose to perform same operation on columns                               *;
*-----------------------------------------------------------------------------*;
  
  proc transpose data=Mammo_Int1 out=Mammo_Int2;
	var b1-b2560;
	id count;
  run;
 
  data Mammo_Int2;
   set Mammo_Int2;
	count=_n_;
  run;

  *Use expand for bilinear interpolation*;
  proc expand data=Mammo_Int2 out=Mammo_Int3;
	convert _1 - _2896/method=join;
	id count;
  run;

*-----------------------------------------------------------------------------*;
* Tranpose to get origianl shape                                              *;
*-----------------------------------------------------------------------------*;
  proc transpose data=Mammo_Int3 out= Mammo_Int4 (drop=_NAME_);
	var _1 - _2896;
	id _NAME_;
  run;

*-----------------------------------------------------------------------------*;
* Keep only variables which can be used to create the interpolated image      *;
*-----------------------------------------------------------------------------*; 
 
  data Mammo_Int5;
    set Mammo_Int4;
    count=_n_;
  run;

  data Mammo_finalInt;
    set Mammo_Int5;
      where 1175<count<=1755;
      keep b1094 - b1605;
  run;


*-----------------------------------------------------------------------------*;
* Output Image using macro                                                    *;
*-----------------------------------------------------------------------------*; 

  data _null_;
     set Mammo_finalInt;
       file "&root.CSV_TXT\Mammogram_interpolation.txt" DELIMITER= ' ' lrecl=1000000 FLOWOVER;
        put b1094 - b1605;
  run; 


  %outImage(work,"&macro_root.BMP\\Source\\Mammogram_src.bmp$","&macro_root.CSV_TXT\\Mammogram_interpolation.txt$","&macro_root.BMP\\Created\\Mammogram_interpolation.bmp$");

  
