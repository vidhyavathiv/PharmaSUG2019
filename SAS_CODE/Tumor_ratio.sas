*-----------------------------------------------------------------------------*;
* Define the window of the tumor and brain using the following macro values.  *;
*-----------------------------------------------------------------------------*;
**Tumor**;
  %let Tx_begin    = 98;
  %let Tx_finish   = 147;
  %let Ty_begin    = 169;
  %let Ty_finish   = 240;

**Brain**;
  %let Bx_begin    = 2;
  %let Bx_finish   = 299;
  %let By_begin    = 2;
  %let By_finish   = 335;

*-----------------------------------------------------------------------------*;
* If pixel values are <= 0.35 (closer to 0)  then redefine them as 0 else as 1*;
* Remove last 2 rows and Cols as they are white and interfere with data values*;
*-----------------------------------------------------------------------------*;
  data brain_area1;
   set PT_3;
    array a{*} a1 - a300;
    array b{*} b1 - b300;
  
     do i = 1 to 300;
       if a{i} <= 0.35 then b{i} = 0;
	   else  b{i} = 1;
    end;
    drop a1 -a300 ;

	 if &By_begin. <= row_order  <= &By_finish.;
	 keep b&Bx_begin. - b&Bx_finish.;
  run;   

*-----------------------------------------------------------------------------*;
* Define row numbers when the value of the pixel is > 0.                      *;
* Find the maximum and minimum of the rows                                    *;
*-----------------------------------------------------------------------------*;
  data brain_area2(drop= b&Bx_begin. - b&Bx_finish. y&Bx_begin. - y&Bx_finish. i); 
     set brain_area1; 
       array original_ {*} b&Bx_begin. - b&Bx_finish. ; 
       array row_      {*} y&Bx_begin. - y&Bx_finish.; 
       array output_   {*} z&Bx_begin. - z&Bx_finish.; 

       do i= 1 to dim(original_); 
          row_{i}=_n_; 
         if original_{i}>0 then output_{i}=y{i}; 
      end; 
   run; 

   proc means data=brain_area2; output out=brain_area3; 
	var z&Bx_begin. - z&Bx_finish.; 
   run; 

*-----------------------------------------------------------------------------*;
* Transpose the stat values. Define area = Max pixel row - Min pixel row +1   *;
* Find the sum of all non- missing area values and store in brain_area        *;
*-----------------------------------------------------------------------------*;

   proc transpose data= brain_area3 out= brain_area4; 
     id _STAT_; 
   run; 

   data brain_area4;
	 set brain_area4; 
	  where _NAME_ ^IN ('_TYPE_', '_FREQ_'); 
	  area=MAX-min+1; 
   run;
 
   proc means data= brain_area4 sum; 
     var area; 
	 output out= brain sum = brain_area;
   run;

*-----------------------------------------------------------------------------*;
* If pixel values are <= 0.20 then redefine them as 0 else as 1. Remove last  *;
* 2 rows and Cols as they are white.                                          *;
*-----------------------------------------------------------------------------*;

   data tumor_area1;
	  set PT_3;
  
        array a{*} a1 - a300;
        array b{*} b1 - b300;
  
        do i = 1 to 300;
          if a{i} <= 0.20 then b{i} = 0;
	      else  b{i} = 1;
        end;
        drop a1 -a300 ;

      if &Ty_begin. <= row_order <= &Ty_finish.;;
	  keep b&Tx_begin. - b&Tx_finish.;
   run;

*-----------------------------------------------------------------------------*;
* Define row numbers when the value of the pixel is > 0.                      *;
* Find the maximum and minimum of the rows                                    *;
*-----------------------------------------------------------------------------*;

   data tumor_area2(drop= b&Tx_begin. - b&Tx_finish. y&Tx_begin. - y&Tx_finish. i); 
	  set tumor_area1; 
       array original_ {*}  b&Tx_begin. - b&Tx_finish. ; 
       array row_      {*}  y&Tx_begin. - y&Tx_finish. ;
       array final_    {*}  z&Tx_begin. - z&Tx_finish. ;

       do i= 1 to dim(original_); 
          row_{i}=_n_; 
         if original_{i}>0 then final_{i}=row_{i}; 
      end; 
   run; 

   proc means data=tumor_area2; output out = tumor_area3; 
	 var z&Tx_begin. - z&Tx_finish.; 
   run; 
*-----------------------------------------------------------------------------*;
* Transpose the stat values. Define area = Max pixel row - Min pixel row +1   *;
* Find the sum of all non- missing area values and store in tumor_area        *;
*-----------------------------------------------------------------------------*;

   proc transpose data= tumor_area3 out= tumor_area4; 
     id _STAT_; 
   run; 

   data tumor_area4;
	 set tumor_area4; 
	  where _NAME_ ^IN ('_TYPE_', '_FREQ_'); 
	  area=MAX-min+1; 
   run;
 
   proc means data= tumor_area4 sum; 
     var area;
     output out = tumor (drop = _FREQ_) sum = tumor_area; 
   run;

*-----------------------------------------------------------------------------*;
* Merge the brain and tumor datasets by _TYPE_ and obtain ratio of the area of*;
* tumor/ area of brain                                                        *;
*-----------------------------------------------------------------------------*;
   data ratio_area;
	 merge brain tumor;
	  by _TYPE_;
	   ratio = tumor_area/brain_area;
   run;



