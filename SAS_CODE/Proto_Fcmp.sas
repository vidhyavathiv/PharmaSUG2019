*-----------------------------------------------------------------------------*;
* Macro         : PROTO_FCMP(dll_,output_folder)         		              *;
* Parameters	: dll_          - Path/name of dll file                       *;
*                 output_folder - Library to store PROTO and FCMP dataset     *;
* Result        : PROTO and FCMP datasets created in &output_folder.          *; 
* Description	: Initialization setup before Image can be written/read       *;
*-----------------------------------------------------------------------------*;

%macro proto_fcmp(dll_,output_folder);

	proc proto package=&output_folder..Proto.ImageManipulation
			   label  = "Image Manipulation - Read from BMP and re-create BMP";

     **call the compiled ImageManipulation.dll file**;
	       link "&dll_.";

     **Define the external C functions with arguments**;
     **IOTYPE = Input to ensure all arguments are read-only **;
 
		int  writePixelsToFile (char* SourceImage/iotype=input, char* CSVOutput/iotype=input)                                  label = "BMP to CSV ";
		void createBMPFromFloat(char* SourceImage/iotype=input, char* TextInput/iotype=input, char* FinalOutput/iotype=input)  label = "Text to BMP";

	run;

	**Use INLIB= to obtain PROTO information of external functions**;
    **Use OUTLIB= to store the FCMP information of wrapper functions created in this step**;
	proc fcmp inlib = &output_folder..Proto
	          outlib= &output_folder..FCMP.ImageManipulation;

			  
	 **Use function and subroutine statements to declare the wrapper functions in data steps.**;
     **Use endsub to end  function/subroutine and return(exp) to return a value if required.**;
	
	    function sas_bmp2csv(SourceImage $ , CSVOutput $);
	       val = writePixelsToFile(SourceImage, CSVOutput);
		   return(val);
	    endsub;

	    subroutine sas_txt2bmp(SourceImage $, TextInput $, FinalOutput $);
	      call createBMPFromFloat(SourceImage, TextInput, FinalOutput);
	    endsub;
	quit;


%mend proto_fcmp;

*-----------------------------------------------------------------------------*;
* Macro         : GETIMAGE(folder,SourceImage, CSVOutput)  		              *;
* Parameters	: folder      - location of PROTO and FCMP datasets           *;
*                 SourceImage - Input Image with path in bmp format           *;
*                 CSVOutput   - Path of file in csv format                    *;
* Result        : Stores pixel values of SourceImage (bmp) in CSVOutput (csv) *; 
* Description	: Reads an image in bmp format and store in csv file.         *;
*-----------------------------------------------------------------------------*;
%macro getImage(folder, SourceImage, CSVOutput);
   
   **Search and call prototype information from PROTO and FCMP datasets**;	
    options cmplib=(&folder..Proto &folder..FCMP) ;
    
	**If csv file is created then resultant = 0, else resultant = -1**; 
	data  input_resultant;
	 length resultant 8;
	     resultant = sas_bmp2csv (&SourceImage.,&CSVOutput.);
	run;
%mend getimage;


*-----------------------------------------------------------------------------*;
* Macro         : OUTIMAGE(folder,SourceImage,TextInput,FinalOutput)          *;
* Parameters	: folder      - location of PROTO and FCMP datasets           *;
*                 SourceImage - Path of the Source file in bmp format         *;
*                  TextInput   - Csv/Txt file which contains unsigned numbers  *;
*                 FinalOutput - Path of output bmp file                       *;
* Result        : Create FinalOutput in bitmap format                         *; 
* Description	: Create bitmap file using header information from source     *;
*                 image and information from matrix values in interim csv file*;
*-----------------------------------------------------------------------------*;
%macro outImage(folder, SourceImage, TextInput, FinalOutput);
    
	**Search and call prototype information from PROTO and FCMP datasets**;	
    options cmplib=(&folder..Proto &folder..FCMP) ;
    
	**create the output image using function sas_txt2bmp**; 
    data _null_;
      call sas_txt2bmp(&SourceImage., &TextInput., &FinalOutput.);
    run;
  quit;
%mend outImage;

*-----------------------------------------------------------------------------*;
* Macro         : CHECK_ERRLOG()                                              *;
* Parameters	: No parameters passed                                        *;
* Result        : Creates  global macros - last_col and no_cols               *; 
* Description	: Extracts information regarding the last column from         *;
*                 Error log created in current in the current directory and   *;
*                 creates global macros                                       *;
*-----------------------------------------------------------------------------*;
%macro check_errlog();
 %global last_col no_cols;

  data err_log;
    infile "Error.log" truncover;
    input #1 Log_results $60. @;
  run;

  data row_3;
   set err_log ;
     if _N_ = 3 and index(Log_results,'Uneven') = 0 ;
	   col_part   = scan(Log_results,2,',');
	   lastcol    = 'a'||strip(scan(col_part,2,'='));
	   call symput ('last_col',lastcol);

	   lastcol_value = strip(scan(col_part,2,'='));
	   call symput ('no_cols', lastcol_value);
  run;

%mend check_errlog;
 





