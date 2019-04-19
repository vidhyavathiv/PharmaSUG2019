# PharmaSUG2019
AD279

To execute and test the programs and the relevant outputs, you will need the following:
1. Windows 32 or 64 bit machine
2. C compiler with gcc option in their machine
3. SAS 9.2 and above with additional packages that load PROC IML/EXPAND.

Steps of execution:
1. Create a directory structure which has the below layout:                                                                                         
Main folder: C:\Image_Processing\
Sub folder[1]: BMP
Sub Sub folder[1a]: Created
Sub Sub folder[1b]: Source
Sub folder[2]: C_CODE
Sub folder[3]: CSV_TXT
Sub folder[4]: DLL_32
Sub folder[5]: DLL_64
Sub folder[6]: SAS_CODE
2. The C code is independent of the operating system. For a Windows computer (with a 32 bit C compiler), execute the following code in DOS:
gcc -c C:\IMAGE_PROCESSING\C_CODE\ImageManipulation.c
gcc -shared -o C:\IMAGE_PROCESSING\DLL_32\ImageManipulation.dll ImageManipulation.o
For a 64 bit compiler, the following needs to be executed:
gcc -c C:\IMAGE_PROCESSING\C_CODE\ImageManipulation.c
gcc -shared -m64 -o C:\IMAGE_PROCESSING\DLL_64\ImageManipulation.dll ImageManipulation.o
This creates the "ImageManipulation.dll" file in the " C:\IMAGE_PROCESSING\DLL_32" or the "C:\IMAGE_PROCESSING\DLL_64" as appropriate. 
Position the DLL files into the 32 bit and 64 bit locations as appropriate.
3. As per this directory structure, the *.bmp files should be located at "C:\IMAGE_PROCESSING\BMP\Source".
4. In the folder " C:\image_processing\sas_code", you will find the SAS codes:
  a. In order to replicate the results in section 3.1, you can run: Mammogram_magnify.SAS
  b. In order to replicate the results in section 3.2, you can run: Mammogram_EM.SAS
  c. In order to replicate the results in section 4, you can run: Tumor.SAS and Tumor_ratio.SAS
  d. The Proto_Fcmp.sas has the macros that specify the interface between the SAS and C.
In these programs, the following variables declare the path: root, macro_root, dll_root. The current dll root is specying the 32 bit folder. If the reviewers are using a 64 bit SAS, they will need to update this to "%let dll_root = %str(C:\IMAGE_PROCESSING\DLL_64\);"in the SAS code.
Further, if the reviewer wishes to re-locate these files, then an appropriate update of the global variables will be required.
