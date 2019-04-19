/*************************************************************************
 *
 * File		    : ImageManipulation.c  (C File)
 * Description	: Functions in the file reads pixels from .bmp files and
 *				  creates the bmp file by reading the pixel values.
 * 				  works for 8 and 24 bit bmp image formats.
 * Compilation	: gcc -c ImageManipulation.c
 *				  gcc -shared -o ImageManipulation.dll ImageManipulation.o
 * Source       : DreamInCodeForum (2009).  URL http://www.dreamincode.net/forums/topic/147643-read-bmp-pixel-by-pixel/
 ************************************************************************/

#include <stdio.h>
#include <string.h>

/* Structure that holds the bitmap header information */
typedef struct {
   unsigned int width;
   unsigned int height;
   unsigned int planes;
   unsigned short bitcount;
   unsigned int size;
} BITMAPINFOHEADER;

/* Structure that holds the bitmap pixel data i.e., RGB values */
typedef struct {
   unsigned char blue;
   unsigned char green;
   unsigned char red;
} PIXEL;

/* Global Variables */
/* File pointer points to the log file and character array is a temporary buffer */
FILE *errLog = NULL;
char buff[250];

/*************************************************************************
 * Method		: Tokenize()
 * Input		: Filename as character array
 * Returns		: None
 * Description	: Path and filename obtained from SAS needs to have a "$"
 *            	: delimiter. This allows the functions to accept each  
 *                strings (files) until it see "$". 
 **************************************************************************/
void Tokenize(char fname[])
{
    int i = 0, j = 0;
    memset(buff, '\0', sizeof( buff ));
    while(fname[i] != '$')
    {
        buff[j++] = fname[i++];
    }
}

/*************************************************************************
 * Method		: getImageData()
 * Input		: file pointer
 * Returns		: BITMAPINFOHEADER
 * Description	: Method reads the header information of the given input
 *		  		  bitmap file.
 **************************************************************************/
BITMAPINFOHEADER getImageData(FILE *image)
{
	FILE *x;
	x=image;
	BITMAPINFOHEADER h;

	fseek(x,2,SEEK_SET);
	fread(&h.size,4,1,x);
	printf("Size=%d\n",h.size);
	fseek(x,18,SEEK_SET);
	fread(&h.width,4,1,x);
	fseek(x,22,SEEK_SET);
	fread(&h.height,4,1,x);
	printf("Width=%d\tHeight=%d\n",h.width,h.height);
	fseek(x,26,SEEK_SET);
	fread(&h.planes,2,1,x);
	printf("Number of planes:%d\n",h.planes);
	fseek(x,28,SEEK_SET);
	fread(&h.bitcount,2,1,x);
	printf("Bit Count:%d\n",h.bitcount);

	return h;
}


/*************************************************************************
 * Method		: writePixelsToFile()
 * Input		: inFileName - Bitmap file name whose pixels are to be read
 *				  outFileName- Text file to which the pixel values are written
 * Returns		: 0 on successful execution and -1 on Error
 * Description	: Method reads the pixel values from given bitmap file
 *				  and writes the pixel values alone to another file (csv) 
 *				  after filtering the header information.
 **************************************************************************/
int writePixelsToFile(char inFileName[], char outFileName[])
{
	FILE *image,*image1,*test = NULL;
	BITMAPINFOHEADER bih;
    unsigned char headerData[1078];
	unsigned int i,j=1,padding = 0, len = 0;
	unsigned char temp[4], bit;
	int column = 0, row = 0, col=0;

  /* write the log details into Error.log file in current working dir. */
    errLog = fopen("Error.log", "w+");

  /* Tokenize is required when invoking the functions from SAS module */
	Tokenize(inFileName);
	inFileName = buff;

    fprintf(errLog, "Processing started\n");
	image=fopen(inFileName,"rb+");

	while(image==NULL)
	{
		fprintf(errLog, "Error! File %s open failed\n", inFileName);
		return -1;
	}
    fprintf(errLog, "Processing the source file %s\n", inFileName);
	
  /* Read the Image header details here */
	bih=getImageData(image);
    int bcount = bih.bitcount/8;
    fread(&headerData,sizeof(headerData),1,image);

	PIXEL p;
	padding = bih.width % 4;
	if(padding != 0 )
	   padding = 4 - padding;

	Tokenize(outFileName);
	outFileName = buff;
	test=fopen(outFileName,"wb+");

  /* Point the file pointer beyond first 54 bytes i.e., header info*/
	fseek(image,54,SEEK_SET);

  /* Loop through the file by incrementing the counter by bitcount times.
	 In parallel, write the read pixel values (RGB) to another file for
	 further processing (depends on the bitcount type - 8 or 24)*/

	if(bcount == 3)
	{
		for(i=0;i<(bih.size-54);i+=3)
		{
            len = fread(&p,sizeof(p),1,image);
            if(!feof(image) && len > 0)
            {
                if(test)
                {
                    float val = (p.blue + p.green + p.red)/3;
                    fprintf(test,"%f ",val/255);
                    if(padding != 0)
                       fread(&temp, padding, 1,image);
                    col++;
                }
                if((j%bih.width) == 0 && j > 0)
                {
                    fprintf(test, "\n");
                    row++; column = col; col = 0;
                }
                j++;
            }
		}
	}
	else if (bcount == 1)
	{
		for(i=0;i<(bih.size-54);i+=1)
		{
			len = fread(&bit,sizeof(bit),1,image);
			if(!feof(image) && len > 0)
			{
				if(test)
				{
                    float val = bit;
                    fprintf(test,"%f ",val/255);
                    if(padding != 0)
                      fread(&temp, padding, 1,image);
                    col++;
				}
				if((j%bih.width) == 0 && j > 0)
				{
                    fprintf(test, "\n");
                    row++; column = col; col = 0;
				}
				j++;
			}
		}
	}
	fprintf (errLog, "The Rows = %d, Columns = %d\n",row, column);

  /* Below code bit is to make the data set handling in SAS  easy*/
	if (col > 0 && column != col)
	{
		fprintf(errLog,"The image is uneven and has additional %d columns in %d row\n", col, ++row);
		while(col < column)
		{
			fprintf(test,"%f ",0.0);
			if(padding != 0)
				fread(&temp, padding, 1,image);
			col++;
		}
	}

	fprintf(errLog, "Processing Successful\n");
	fclose(image);
    fclose(errLog);
	if(test)
        fclose(test);

    return 0;
}


/*************************************************************************
 * Method		: createBMPFromFloat()
 * Input		: sourceImageFile- name of the Bitmap file.
 *				  textInputFile  - name of the text file from which the 
 *				  pixels are to be read.
 *                finalOutput    - name of the output bitmap file.
 * Returns   	: None
 * Description	: Method reads the pixel values from a given input file
 *				  and creates a new bitmap file. Header information is
 *				  read from the input source bitmap file.
 **************************************************************************/
void createBMPFromFloat
		(char sourceImageFile[], char textInputFile[], char finalOutput[])
{

	FILE *image,*input,*textFile = NULL;
	BITMAPINFOHEADER bih;
    unsigned char headerData[1078];
	unsigned int i,j;
	char temp[4] = {0,0,0,0}, bit;

  /* Write the log details into Error.log file in current working dir. */
    errLog = fopen("Error.log", "a+");
    Tokenize(sourceImageFile);
    sourceImageFile = buff;

    fprintf(errLog, "SourceImageFile = %s\n", sourceImageFile);
	input=fopen(sourceImageFile,"rb+");

	while(input==NULL)
	{
		fprintf(errLog,"Error! File %s open failed\n", sourceImageFile);
	}
    fread(&headerData,sizeof(headerData),1,input);

  /* Read the Image header details here*/
	bih=getImageData(input);
    int bcount = bih.bitcount/8;

    Tokenize(finalOutput);
    finalOutput = buff;
    fprintf(errLog, "finalOutput = %s\n", finalOutput);
	image=fopen(finalOutput,"wb+");
	if(image == NULL)
	{
		fprintf(errLog,"Error! File %s open failed\n", finalOutput);
	}
	fwrite(&headerData,sizeof(headerData),1,image);

	PIXEL p, charImage;

    Tokenize(textInputFile);
    textInputFile = buff;
    fprintf(errLog, "textInputFile = %s\n", textInputFile);
	textFile=fopen(textInputFile,"rb+");
	if(textFile == NULL)
	{
		fprintf(errLog,"Error! File %s open failed\n",textInputFile);
	}

    float myvariable = 0;
	unsigned int m = 0, n = 0;
	unsigned int padding = bih.width % 4;

	if(padding != 0 )
	   padding = 4 - padding;

  /* Point the file pointer beyond first 54 bytes i.e., header info
	 in both image and input file */
	 
	fseek(image,54,SEEK_SET);
	fseek(input,54,SEEK_SET);

  /* Loop through the file by incrementing the counter by bitcount times.
	 In parallel, write the read pixel values (RGB) to another file for
	 further processing (depends on the bitcount type - 8 or 24)*/
	  if (bcount == 3)
    {
		for(m = 0;m < (bih.size - 54); m+=3)
		{
			if (!feof(textFile))
			{
                fscanf(textFile, "%f", &myvariable);
                unsigned int val = (myvariable*255);
                charImage.blue=charImage.green=charImage.red=(unsigned char)val;
                p=charImage;
                fwrite(&p,sizeof(p),1,image);

                if(padding != 0)
                {
                    fseek(input,3,SEEK_CUR);
                    fread(&temp, padding, 1, input);
                    fwrite(&temp, padding, 1,image);
                }
			}
		}
	}
	else if (bcount == 1)
	{
		for(m = 0;m < (bih.size - 54); m+=1)
		{
			if (!feof(textFile))
			{
				fscanf(textFile, "%f", &myvariable);
				unsigned int val = (myvariable*255);
				bit=(unsigned char)val;
				fwrite(&bit,sizeof(bit),1,image);

				if(padding != 0)
				{
                    fseek(input,1,SEEK_CUR);
                    fread(&temp, padding, 1, input);
                    fwrite(&temp, padding, 1, image);
				}
			}
		}
	}
    fclose(textFile);
	fclose(input);
	fclose(image);
	fclose(errLog);
}


