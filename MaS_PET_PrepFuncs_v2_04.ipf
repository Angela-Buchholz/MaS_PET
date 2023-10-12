#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//======================================================================================
//	MaS_PET_prepFuncs contains all basic functions to load and prepare data for PMF calcualtions with the MaS-PET software. 
//	Copyright (C) 2023 Angela Buchholz 
//
//	This file is part of MaS-PET.
//
//	MaS-PET is a free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation,
//	either version 3 of the License, or any later version.
//
//	Mas-PET is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//	See the GNU Lesser General Public License for more details.
//
//	You should have received a copy of the GNU Lesser General Public License along with MaS-PET. If not, see <https://www.gnu.org/licenses/>. 
//======================================================================================

// this procedure file contains all basic functions needed during data loading and preparation for PMF

//======================================================================================
//======================================================================================

// Purpose:	check for ions which are mostly negative in one sample
//				user can decide if they want to set those to 0 or keep tham as negative values
//				this operates on the combined data set created with makeCombi()

// Input:		combiName_str:	string name of datafolder to operate on							
//				waveNames:		txt Wave with names for data waves
//				badValue:			how many percent of points have to be negative to deam this a bad sample for this ion
//				Explist:			txt wave with Experiment names (for sanity check of idxSample)
// Output:	MSdata and MS_error will be changed

FUNCTION MPprep_checkNegIons(combiName_str,WaveNames,BadValue,Explist)

String combiname_Str
Wave/T WaveNames
Variable badValue
Wave/T Explist

SVAR abortStr=root:app:abortStr
String alertStr

// check input value
IF (BadValue<0 && badValue>100)
	abortStr="MPprep_checkNegIons():\r\rPercentage value must be between 0 and 100.\rbadValue: "+num2Str(badValue)
ENDIF

// get data waves 
Wave MSdata=$(combiname_Str+":"+Wavenames[0])
Wave MSerr=$(combiname_Str+":"+Wavenames[1])
Wave exactMZ=$(combiName_str+":"+WaveNames[2])
Wave/T ionLabel=$(combiName_str+":"+WaveNames[3])
Wave Tdesorp=$(combiName_str+":"+WaveNames[4])

Variable nor=dimsize(MSdata,0)
Variable noc=dimsize(MSdata,1)

//check data for negative values
MatrixOP/FREE test=minVal(MSdata)

IF (test[0]>=0)	// nothing found -> end this now
	print " + no negative values found in Wave: "+ combiname_Str+":"+Wavenames[%MSdataName]
	print " + no changes done"
	RETURN -1
ENDIF

// if at least one negative value was found
// -> loop through ions and then samples to see if something needs to be done
//---------------------------------------------------------------

// get info on sample idx
String IdxSampleName="idxSample"
IF (stringmatch(Wavenames[%MSdataName],"noNans_*"))	// check if noNans is used
	IdxSampleName="noNans_idxSample"
ENDIF

MPaux_check4IDXSample(idxSampleName,combiName_str,Tdesorp,Explist)	// if user clicks abort inside this, this will abort function

Wave/D idxSample=$(combiName_str+":"+idxSampleName)

Variable nos=dimsize(idxSample,0)	// number of samples

Make/FREE/D/N=(nos,noc) negIon_flag_sample=0 // this will have 1 for those parts that should be set to 0
Make/FREE/D/N=(nor,noc) negIon_flag=0			// this will have 1 for those parts that should be set to 0

// loop through ions and samples
Variable ss,ii,jj
Variable pointsInSample
Variable counter=0

FOR(ss=0;ss<nos;ss+=1)	// sample loop
	
	pointsInSample=idxSample[ss][1]-idxSample[ss][0]+1
	
	// cut out current sample
	Make/FREE/D/N=(pointsInSample,noc) currentSample
	currentSample=msdata[p+idxSample[ss][0]][q]
	
	currentSample = currentsample[p][q]<0 ? Inf : currentsample[p][q]
	
	// find number of INF
	Wavestats/Q/PCST/W/M=1 currentSample
	Wave M_wavestats
	
	Make/FREE/D/N=(noc) numberOfINF
	numberOfINF=M_wavestats[2][p]	// row 2 is number of INF
	
	// index of ions with badValue% of data points below 0
	Extract/INDX/FREE numberOfINF, idxBad, numberOfINF>badValue/100*pointsInSample
	
	IF (numpnts(numberOfINF)>0)
	
		// set neg ion flag	for time series
		negIon_flag[idxSample[ss][0],idxSample[ss][1]][] = numberOfINF[q]>badValue/100*pointsInSample ? 1 : 0

		// set neg ion flag	for samples
		negIon_flag_sample[ss][] = numberOfINF[q]>badValue/100*pointsInSample ? 1 : 0

		// set marker that mostly negative ions were found
		IF (sum(negIon_flag)>0)
			counter+=1
		ENDIF
		
	ENDIF
	
ENDFOR	// sample loop

IF(counter>0)
	alertStr="Ions with negative values for "+num2Str(badValue)+"% of the values in indivudual samples detected."
	alertStr+=" Ions and samples are listed in wave: \r"+combiname_Str+":info_negValue"
	alertStr+="\r\rSet these negative values to 0 (YES) or ignor them?\r\r"
	alertStr+="NOTE: other sporadic negative values will not be changed!"

	DoAlert 1, alertStr
	
	// store info in text wave
	SumDimension/D=0 /DEST=TestSum negIon_flag_sample
		
	Wave testSum
		
	// find ions with at least 1 problematic sample
	Extract /FREE/INDX testSum,idx_negIons, testSum>0
	
	// wave to hold info about detected problematic ions
	Make/O/T/N=(numpnts(idx_negIons),3) $(combiname_Str+":info_negValue")	// column 1: ion number, 2: ion label, 3: sample number with problem
	Wave/T info_negValue=$(combiname_Str+":info_negValue")
	
	String NoteStr="Ions identified to have "+num2Str(badValue)+"% of their data points in one sample <0"
	NoteStr+="\rColumn 1:Ion number;Column 2:IOn label;Column 3:sample numbers"
		
	Note info_NegValue,NoteStr
	
	FOR (ii=0;ii<numpnts(idx_negIons);ii+=1)	// ion loop

		info_negValue[ii][0]=num2str(idx_negIons[ii])		// ion number
		info_negValue[ii][1]=ionLabel[idx_negIons[ii]]	// ion label
		
		// find samples
		Make/FREE/D/N=(nos) currentTest
		currentTest=negIon_flag_sample[p][idx_negIons[ii]]
		
		Extract/FREE/INDX currentTest,idx_negSample,currentTest==1

		String printStr=""
		FOR (jj=0;jj<numpnts(idx_negSample);jj+=1)
			printStr+=num2Str(idx_negSample[jj])+";"
		ENDFOR
		info_negValue[ii][2]=printStr
		
	ENDFOR	// ion loop

	// set msdata values to 0 if selected
	IF (V_flag==1)
		// change data wave name
		Wavenames[0]+="_1"
		Wavenames[1]+="_1"
		
		Make/O/D/N=(nor,noc) $(combiname_Str+":"+Wavenames[0])
		Wave msdata_1=$(combiname_Str+":"+Wavenames[0])
		NoteStr=Note(MSdata)
		NoteStr+="\rions with "+num2Str(badValue)+"% of datapoints in a sample are set to 0"
		Note MSdata_1,NoteStr
		
		Make/O/D/N=(nor,noc) $(combiname_Str+":"+Wavenames[1])
		Wave mserr_1=$(combiname_Str+":"+Wavenames[1])
		NoteStr=Note(MSerr)
		NoteStr+="\rions with "+num2Str(badValue)+"% of datapoints in a sample are set to 1"
		Note MSerr_1,NoteStr
				
		// set negative ions to 0 and error to 1
		MSdata_1 = negIon_flag[p][q] ==1 ? 0 : msdata[p][q]
		MSerr_1 = negIon_flag[p][q] ==1 ? 1 : mserr[p][q]	
		
		// inform user
		print " + ions with "+num2str(badValue)+"% negative points in samples were set to 0 for these samples"
		print "   check table for details"
		print "   NOTE: new wavenames for MS data and MS error waves set in panel"
	
	ENDIF
	
	// display info in table
	MPaux_ShowWavesAsTable(combiname_Str+":info_negValue","Table_negIons")
	
	// clean up
	KillWaves/Z testSum
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	check if MS data has empty columns/rows
//				create waves with the offensive columns/rows removed or replaced by suitable values
//
// Input:		combiName_str:	string name of datafolder to operate on							
//				waveNames:		txt Wave with names for data waves
//				expList:			txt wave with names of samples (needed for sanity check if idxSample is calculated)
// Output:	duplicates of data waves with 'noNans_' prefix with offensive columns/rows removed

FUNCTION MPprep_checkMSdata4NaN(combiName_str,WaveNames,ExpList)

String combiname_Str
Wave/T WaveNames
Wave/T/Z ExpList

SVAR abortStr=root:app:abortStr

// check that explist waves exist
IF (!waveexists(ExpList))
	abortStr="MPprep_checkMSdata4NaN():\r\rExpList wave not found:\r"
	abortStr+=GetWavesDataFolder(ExpList,2)
	MPaux_abort(AbortStr)
ENDIF

// wave with MS data
Wave MSdata=$(combiName_str+":"+WaveNames[%MSdataName])

Variable nor=dimsize(MSdata,0)
Variable noc=dimsize(MSdata,1)


// create duplicates with nonans_ prefix
Wave MSerr=$(combiName_str+":"+WaveNames[%MSerrName])
Wave exactMZ=$(combiName_str+":"+WaveNames[%MZname])
Wave/T ionLabel=$(combiName_str+":"+WaveNames[%LabelName])
Wave Tdesorp=$(combiName_str+":"+WaveNames[%TNAme])

// make new waves -> this overwrites existing  noNaNs waves!
Duplicate/O MSdata,$(combiName_str+":noNans_"+WaveNames[%MSdataName])
Duplicate/O MSerr,$(combiName_str+":noNans_"+WaveNames[%MSerrName])
Duplicate/O exactMZ,$(combiName_str+":noNans_"+WaveNames[%MZname])
Duplicate/O ionLabel,$(combiName_str+":noNans_"+WaveNames[%LabelName])
Duplicate/O Tdesorp,$(combiName_str+":noNans_"+WaveNames[%TNAme])

Wave nonans_MSdata=$(combiName_str+":noNans_"+WaveNames[%MSdataName])
Wave nonans_MSerr=$(combiName_str+":noNans_"+WaveNames[%MSerrName])
Wave nonans_exactMZ=$(combiName_str+":noNans_"+WaveNames[%MZname])
Wave/T nonans_ionLabel=$(combiName_str+":noNans_"+WaveNames[%LabelName])
Wave nonans_Tdesorp=$(combiName_str+":noNans_"+WaveNames[%TNAme])

// add Fig Time if it exists
Variable now=3	// number of waves that need adjustment if row is NaN
IF (!stringmatch("",Wavenames[%FigTimeName]))
	 
	IF (Waveexists($(combiName_str+":"+WaveNames[%FigTimeName])))
		now=4
		Wave FigTime=$(combiName_str+":"+WaveNames[%FigTimeName])
		duplicate/O FigTime,$(combiName_str+":noNans_"+WaveNames[%FigTimeName])
		Wave nonans_FigTime=$(combiName_str+":noNans_"+WaveNames[%FigTimeName])
	ENDIF

ENDIF

// check if IDXsample wave exists
String IdxSampleName="idxSample"

MPaux_check4IDXSample(IdxSampleName,combiName_str,Tdesorp,expList)	// if user clickes abort in here, this will abort function
Wave idxsample=$(combiName_str+":IdxSample")

// make nonans_ wave
Duplicate/O IdxSample,$(combiName_str+":noNans_IdxSample")
Wave nonans_idxSample=$(combiName_str+":noNans_IdxSample")

// find nan and zero columns
MAke/T/FREE/N=(4) Wavenames_columns=WaveNames
MPprep_do_checkMSdata4NaN(combiName_str,Wavenames_columns,0)

// find nan and zero rows
MAke/T/FREE/N=(now) Wavenames_rows
IF (now==3)
	Wavenames_rows={WaveNames[%MSdataName],WaveNames[%MSerrName],WaveNames[%TNAme]}	// msdata, mserr,Tdesorp
ELSE
	Wavenames_rows={WaveNames[%MSdataName],WaveNames[%MSerrName],WaveNames[%TNAme],Wavenames[%FigTimeName]}	// msdata, mserr,Tdesorp, FigTime
ENDIF

MPprep_do_checkMSdata4NaN(combiName_str,Wavenames_rows,1)
	
END

//======================================================================================
//======================================================================================

// Purpose:	do the actual check and remove the rows/columns

// Input:		combiName_str:	string name of datafolder to operate on							
//				waveNames4Nans:	txt Wave with names for waves to be handled here
//				type:				0: columns, 1: rows
// Output:	duplicates of data waves with 'noNans_' prefix with offensive columns/rows removed
// called by: MPprep_checkMSdata4NaN

FUNCTION MPprep_do_checkMSdata4NaN(combiName_str,waveNames4Nans,type)

String combiname_Str
Wave/T waveNames4Nans
Variable type

// wave with MS data 
Wave MSdata=$(combiName_str+":"+waveNames4Nans[0])

// get info on sample idx

Wave/D idxSample=$(combiName_str+":idxSample")
Wave/D nonans_idxSample=$(combiName_str+":nonans_idxSample")

SVAR abortStr=root:app:abortStr

// determine which type
String type_str="columns"

IF (type==1)
	type_Str="rows"
	// turn msdata around to use /PCST 
	Matrixtranspose msdata
ENDIF

Variable nor=dimsize(MSdata,0)
Variable noc=dimsize(MSdata,1)

//---------------------------------
// find nan/0 columns/rows
Wavestats/M=1/Q/PCST MSdata

IF (type==1)
	// turn matrix back to normal
	Matrixtranspose msdata
ENDIF

Wave M_Wavestats

// find NAN columns
Make/FREE/D/N=(noc) testNaN=M_Wavestats[1][p]	// number of NaN

testNan/=nor // ==1 if all entries were NaN

Extract/FREE/INDX testNaN,testNan_IDX, testNan==1
Variable numOfNan = numpnts(testNan_IDX)

// find ZERO columns
Make/FREE/D/N=(noc) testZero=M_Wavestats[23][p]	// sum over column

Extract/FREE/INDX testZero,testZero_IDX,testZero==0 && testNaN!=1	// sum is 0 for all naN and all 0 -> exclude the NaN ones
Variable numOfZero = numpnts(testZero_IDX)

Variable nn,zz,ww

// remove columns/rows
IF (numofnan>0 || numOfZero>0)

	abortStr="MPprep_checkMSdata4Nans():\r\rempty "+type_str+" found in wave: "+combiName_str+":"+waveNames4Nans[0]
	abortStr+="\r\rremove "+type_Str+" from data (YES) or ignore (NO)?"
	doalert 1,abortStr
	
	IF(V_flag==1)
		
		//YES
		//remove ions/rows from everywhere
		
		// combine indices for removal
		Concatenate/NP/O {testNan_IDX,testZero_IDX}, remove_Idx	// /FREE flag does not work in Igor 7
		
		FOR (nn=numpnts(remove_IDX)-1;nn>-1;nn-=1)	// loop backwards through columns/rows to be removed
			// loop through waves
			FOR (ww=0;ww<numpnts(waveNames4Nans);ww+=1)
				Wave currentWave=$(combiName_str+":nonans_"+waveNames4Nans[ww])
				
				IF (Wavedims(currentWave)==2)
					//2D waves 
					IF (type==0) // columns are removed
						deletepoints/M=1 remove_Idx[nn],1, currentWave
					ELSE
						deletepoints/M=0 remove_Idx[nn],1, currentWave
					ENDIF
				ELSE
					//1D waves -> remove row
					deletepoints remove_Idx[nn],1, currentWave
				ENDIF
				
			ENDFOR
			
			// handle idxSample wave for row removal
			IF (type==1)
				nonans_idxSample = idxSample[p][q] >= remove_Idx[nn] ? (nonans_idxSample[p][q]-1) : nonans_idxSample[p][q]
			ENDIF
		ENDFOR
		
		// kill wave because Concatenate/FREE dows snot work in IGOR 7
		Killwaves/Z remove_Idx
				
		// inform user about actions
		Wave nonans_MSdata=$(combiName_str+":noNans_"+waveNames4Nans[0])
		
		print "------------"
		print num2Str(numofnan)+" "+type_str+" with only NaNs removed"
		print num2Str(numofzero)+" "+type_str+" with only 0 (or 0 and NaNs) removed"
		print "remaining data matrix is now: "+ num2str(dimsize(nonans_MSdata,0))+" rows and "+num2str(dimsize(nonans_MSdata,1))+" columns"
		print "removed "+type_str+" (NaN, Zero): "
		print testNan_idx
		print testZero_idx
	ELSE
		//NO -> user abort -> go back up to main level
		Wave nonans_MSdata=$(combiName_str+":noNans_"+waveNames4Nans[0])
		
		print "------------"
		print num2Str(numofnan)+" "+type_str+" with only NaNs found"
		print num2Str(numofzero)+" "+type_str+"columns with only 0 found"
		print "user chose to ignore this"
		print "remaining data matrix is now: "+ num2str(dimsize(nonans_MSdata,0))+" rows and "+num2str(dimsize(nonans_MSdata,1))+" columns"
		print "emtpy "+type_str+" (NaN, Zero): "
		print testNan_idx
		print testZero_idx

		RETURN -1
	
	ENDIF

ELSE

	// inform user that nothing changed
	print " + no NaNs or zeros "+type_str+" found -> waves are unchanged"

ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	check for 0 or negativevalues in MS error wave
//				values will be replaced with 1
//				this operates on the combined data set created with makeCombi()

// Input:		MSerr:		Wave with MS error values
//				
// Output:	Mserr values with <=0 are replaced with 1


FUNCTION MPprep_CheckMSerr4Nan(MSerr)

Wave MSerr

Variable nor=dimsize(MSerr,0)
Variable noc=dimsize(MSerr,1)

SVAR abortStr=root:app:abortStr

// use 1D wave and extract

Duplicate/FREE mserr,MSerr_1D
redimension/N=(noc*nor) MSerr_1D

// find NaNs
Extract/FREE/INDX MSerr_1D,NaN_IDX, numtype(MSerr_1D)!=0	// find any Nan

String wavenameStr=getwavesdatafolder(MSerr,2)

IF (numpnts(Nan_IDX)>0)
	
	Make/O/D/N=(numpnts(Nan_IDX),2) root:app:Nan_IDX_2D
	Wave NaN_IDX_2D=root:app:nan_idx_2D
	Note nan_idx_2D,"row and column position of NaN values in MSerr matrix\rfirst column: row index;second column: column index"
	Nan_IDX_2D[][0]=mod(Nan_IDX[p],nor)		// row position
	Nan_IDX_2D[][1]=trunc(nan_idx[p]/nor)	// column position
	
	abortStr="MPprep_CheckMSerr4Nan():\r\r At least 1 value in "+waveNameStr+" is NaN.\r\rrow and column index are stored in root:APP:NaN_IDX_2D"
	abortStr+="\r\rReplace it with 1 (YES) or abort (NO)?"
	
	DoAlert 1, abortStr
	
	IF (V_flag==1)	// YES
		// replace with 1
		MSerr = numtype(MSerr[p][q])!=0 ? 1 : MSerr[p][q]
		print " + NaN values found in MSerr wave. User chose to replace with '1'"
	ELSE	// NO
		// abort
		abort 
	ENDIF
ENDIF

//find 0 or smaller 0
Extract/FREE/INDX MSerr_1D,Neg_IDX, MSerr_1D<=0	// find any 0 or negative value

IF (numpnts(Neg_IDX)>0)
	
	Make/O/D/N=(numpnts(Neg_IDX),2) root:app:Neg_IDX_2D
	Wave Neg_IDX_2D= root:app:Neg_IDX_2D
	Note Neg_IDX_2D,"row and column position of negative of 0 values in MSerr matrix\rfirst column: row index;second column: column index"
	
	Neg_IDX_2D[][0]=mod(Neg_IDX[p],nor)		// row position
	Neg_IDX_2D[][1]=trunc(Neg_IDX[p]/nor)	// column position

	abortStr="MPprep_CheckMSerr4Nan():\r\rAt least 1 value in "+wavenamestr+" is 0 or negative.\r\rrow and column index are stored in root:APP:Neg_IDX_2D"
	abortStr+="\r\rReplace it with 1 (YES) or abort (NO)?"
	
	DoAlert 1, abortStr
	
	IF (V_flag==1)	// YES
		// replace with 1
		MSerr = MSerr[p][q]<=0 ? 1 : MSerr[p][q]
		print " + negative or 0 values found in MSerr wave. User chose to replace with '1'"
	ELSE	// NO
		// abort
		abort 
	ENDIF
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		prepare FIGAERO thermogram data for use in PET
//					can be called standalone or from APP
//					This is the wrapper routine for 
//						- checking that all waves exist in Experiment folders
//						- calculate element numbers from ion labels
//						- calulate error values PL and CN (see Buchholz ACP 2020)
//						- remove iodide mass from exactMZ wave (ionlabels say the same
//
// Input:			expList:		text wave with names of datafolders to operate on
//					Wavenames:	names for waves inside datafolder
//								waves MUST have the same names in all folders
//								order: MSdata,MSerr,exactMZ,ionalabel, Tseries		
//					doElementfromlabel:	1:calculate element numbers from ionlabel wave
//					doError:		1: CN error and data needed to calculate PL ERROR is calculated
//					doRemoveI:	1: remove 127 amu from MZ values for ions with Iodide
//					SaveHIsto:	1: keep the histogram data from PL error data calcuilation
//
// Output:		all new waves will be in the individual sample folders or in a subfolder therein
//					ElementNum:		2D wave with row for each ion and column for each element (currently C;H;O;N;S;I;F;Cl;)
//					MSerr_CN:			CN type error
//					SG error folder:	Waves to determine PL error parameters
//					ExactMZ_noi:		neutral ion mass
// called by:	-

FUNCTION MPprep_prepFIG4PMF(explist,WaveNames,doElement,DoError,doremoveI,SaveHisto)
			
Wave/T expList
Wave/T Wavenames
Variable doElement
Variable doError
Variable doremoveI
Variable SaveHIsto

String oldFolder=getdatafolder(1)

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

abortStr=""

// double check that things exist
IF (!Waveexists(expList)) // experiment list wave
	abortStr ="MPprep_prepFIG4PMF(): 'Explist' wave does not exist: \r\r"+getwavesDataFolder(expList,2)
	MPaux_abort(AbortStr)
ENDIF

IF (!Waveexists(Wavenames))	// waves selected in Panel
	abortStr ="MPprep_prepFIG4PMF(): 'Wavenames' wave does not exist: \r\r"+getwavesDataFolder(Wavenames,2)
	MPaux_abort(AbortStr)
ENDIF

// wavenames
String MSname=Wavenames[%MSdataname]
String MZname=Wavenames[%MZName]
String LabelName=Wavenames[%LabelName]

// store wavelength for check
Make/FREE/D/N=(numpnts(explist)) noi=0

//loop through exp folders and execute stuff
Variable ff
Variable check_DF=0
Variable check_Length=0
Variable check_ionLabel=0

Print "------------------------"
print date() + " "+ time() + "\tpreparing data for combining into one data set:"
		
FOR (ff=0;ff<numpnts(Explist);ff+=1)

	String CurrentFOlder="root:"+Explist[ff]
	Currentfolder=replaceString("root:root:",currentfolder,"root:")
	
	// check if folder exists
	IF (datafolderexists(Currentfolder))

		check_DF+=1
		
		// check if all waves exist
		MPaux_checkPMFWaves(Currentfolder,waveNames,1,ignoreErr=1)
	
		// go to current exp folder
		setdatafolder $(CurrentFOlder)
		
		// get info about number of ions
		Wave/T/Z ionLabels=$""
		Wave/T/Z ionLabels=$labelName
		
		// calc element from label
		IF (doElement==1)
			
			// check wave
			IF (Waveexists($labelName))
				
				Wave/T ionlabels=$labelName
				MPaux_calcElementFromLabel(ionLabels)
			ELSE
				// ion labels are missing
				abortStr+="\rMPprep_prepFIG4PMF():\r\r unable to run calcElementFromLabel_APP(): missing ion names wave: " +labelName+" in Folder: "+Currentfolder
				check_ionLabel+=1
			ENDIF
		ENDIF
		
		// removeIodide
		IF (doremoveI==1)
			
			Wave/T/Z ionlabels=$labelName
			Wave/Z exactMZ=$MZname
			
			// check wave
			IF (Waveexists(ionlabels) && Waveexists(exactMZ))
				// check wave length
				IF (numpnts(ionlabels)==numpnts(exactMZ))
					Wave/T ionlabels=$labelName
					MPaux_removeIodide(exactMZ,ionLabels)

				ELSE
					// addinfo to abortStr
					abortStr+="\rprepFIG4PMF():\r\runable to run removeIodide_APP(): length of waves with MZ values and ion names does not agree\r"
					abortStr+=getwavesDataFolder(ionLabels,2)+" and "+getwavesDataFolder(exactMZ,2)
					check_length+=1
				ENDIF
			ELSE
				IF (doElement==0)	// first part of abortStr was not set yet
				
				ENDIF
				abortStr+="\rMPprep_prepFIG4PMF():\r\r unable to run removeIodide_APP(): missing ion names wave: " +labelName+" in Folder: "+Currentfolder
				
			ENDIF
		ENDIF
		
	ENDIF	// datafolder exists check

ENDFOR	// datafolder loop

//none of the Explist folders existed
IF (check_DF==0)
	Setdatafolder $oldFolder
	abortStr="MPprep_prepFIG4PMF():\r\rnone of the datafolders listed found: "+getwavesDataFolder(Explist,2)
	MPaux_abort(AbortStr)
ELSE
	print "\t+ all waves given in Panel exist for all folders in ExpList Wave"		
ENDIF

IF (doremoveI==1 && check_ionLabel==0)
	print"\t+ removed iodide mass from MZ values -> to use them, switch to "+MZname+"_noi"					
ENDIF

IF (doElement==1 && check_length==0 && check_ionLabel==0)
	print "\t+ calculated elemental composition from ion labels"
ENDIF

// print issues
IF (check_length!=0 || check_ionLabel!=0)
	print "------------------------------"
ENDIF

// give info about length of ionlist
IF(check_length!=0)
	print abortStr
ENDIF

// at least one of the DF was missing the ion label wave
IF (check_ionLabel!=0)
	print abortStr
ENDIF

// calculate MSerr (DoSGerr_app contains ExpList loop)
IF (doError==1)
	
	// calc MSerr_CN and fits for PL error
	// PLerror Panel is created at the end
	MPprep_DoSGerr(expList,WaveNames,saveHisto)
	
ENDIF

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// Purpose:	wrapper function for MPprep_SG_error4PMF() to operate on all samples
//
// Input:		expFolderList:	txt wave with names of experiment folder
//				wavenames:		txt wave with name of waves (msdata,mserr,exactMZ,ionlabel,Tdesorp)
//				SaveHisto:		1: keep histogram data from PL error calculation
// 				
// Output:	details see MPprep_SG_error4PMF()
//				MSerr_CN:	constant noise error
//				opens PLerror panel with MPprep_PLE_PLErr_Panel_main()	 to get user fit for PL error
//
// called by:MPprep_prepFIG4PMF() or stand-alone

FUNCTION MPprep_DoSGErr(expFolderList,waveNames,saveHisto)

Wave/T ExpFolderList	// text wave with names of folders to operate on
Wave/T wavenames
Variable SaveHisto

String concatList_Sij="",concatList_Sij95="",concatList_mass="",concatList_points=""

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF
abortStr=""

// get CNtype value
NVAR CNType=root:APP:CNtype_VAR
IF (!NVAR_exists(CNType))
	Variable/G CNtype=0
ENDIF

// get other stuff
	
Newdatafolder/O/S root:APP:SG_err
Make/D/O/N=(numpnts(expfolderlist),6) s_noise


String MSname=Wavenames[%MSdataname]
MPaux_CheckMSerrName(Wavenames)	// check first if there is an Errorname
String ErrorName=Wavenames[%MSerrName]
String CNErrorName=ErrorName

//catch if error name already has _PL or _CN
CNErrorName=replaceString("_CN",CNErrorName,"")
CNErrorName=replaceString("_PL",CNErrorName,"")
CNErrorName+="_CN"

// loop through experiments
Variable tt=0
Variable check_Err=0

String folderPath=""

FOR (tt=0;tt<numpnts(expFolderList);tt+=1)
	
	Wave sigma_noise=$("")

	folderPath="root:" + expFolderList[tt]+":"
	folderPath=replaceString("root:root:",folderPath,"root:")
	folderPath=replaceString("::",folderPath,":")
	
	// only run if MSdata wave exists
	IF (Waveexists($(folderPath+Wavenames[%MSdataName])))
		
		// check if MSdata has valid points
		Wave MSdata=$(folderPath+wavenames[%MSdataname])
		Wavestats/Q/M=1 MSdata

		IF (numtype(V_avg)==0)
			// calculate SG type error data (sigma noise, histogram values)
			MPprep_SG_error4PMF(expFolderList[tt],wavenames,saveHisto)
			
			concatList_Sij+=folderPath+"SG_err:S_ij;"
			concatList_Sij95+=folderPath+"SG_err:S_ij95;"
			concatList_mass+=folderPath+"SG_err:SignalOfClasses;"
			concatList_points+=folderPath+"SG_err:pointsInClass;"
			
			// get s_noise values
			Wave sigma_noise=$(folderPath+"SG_err:sigma_noise")
			s_noise[tt][]=sigma_noise[q]
			
			// make CN type error
			Wave MSdata=$(folderPath+MSName)
			Wave sigma_noise=$(folderPath+"SG_err:sigma_noise")
			
			Make/O/D/N=(dimsize(MSdata,0),dimsize(Msdata,1)) $(folderPath+CNErrorName)
			Wave MSerr_CN=$(folderPath+CNErrorName)
			
			// minimum error
			Variable MinErr
			SWITCH (CNtype)
				// end
				CASE 0:
					MinErr=sigma_Noise[3]	// last 20 data points
					Wave stdev=$(folderPath+"SG_err:stdevWave_end")
					BREAK
				// all
				CASE 1:
					MinErr=sigma_Noise[1]	// all points
					Wave stdev=$(folderPath+"SG_err:stdevWave")
					BREAK
				// less then median
				CASE 2:
					MinErr=sigma_Noise[5]	// smaller than median
					Wave stdev=$(folderPath+"SG_err:stdevWave_LTmean")
					BREAK
			ENDSWITCH
			
			MSerr_CN=stdev[q] > minErr? stdev[q] : minErr
			Note MSerr_CN,"CN type error\rMSerr_CN=stdevWave_end[q] > "+num2str(minErr)+"? stdevWave_end[q] : "+num2str(minErr)
		ELSE
			abortStr+="MPprep_DoSGErr():\r\r No valid data points in Wave "+Wavenames[%MSdataName]+" in folder "+folderPath+"\r"
			check_Err+=1
		ENDIF
	ELSE
		abortStr+="MPprep_DoSGErr():\r\r Cannot find wave "+Wavenames[%MSdataName]+" in folder "+folderPath+"\r"
		check_Err+=1
	ENDIF
	
ENDFOR

// notify user that MSerr_CN was calculated
print "\t+ calculating error matrix"
IF (check_err==numpnts(expFolderList))	
	
	print "\t\t- MPprep_DoSGErr(): MSdata wave not found in any of the folders. Check input!"
ELSE
	print "\t\t- CN type error was calculated ("+CNErrorName+"). User interaction needed to calculate PL type error."
	print "\t\t- User must change name of MSerr wave in Panel manually."
ENDIF

IF (check_err>0)	// some folders were missing data wave
	print "\t\t- some issues detected:"
	String PrintStr=replaceString("\r\r",abortStr,"\t")
	print "\t\t\t"+PrintStr
ENDIF


//------------------------------
// join data from all experiments to create PL error parameters

IF (check_err!=numpnts(expFolderList))	// run if at least one folder had data
	String WaveNote=Note(sigma_noise)
	Note s_noise, WaveNote
	
	// store S_ij data in one wave
	setdatafolder root:APP:SG_err
	
	// check waves in concat list
	Variable problem=0
	String problemStr=""
	
	IF (!MPaux_checkwavesfromlist(concatList_Sij))
		Wave nonexistIDX
		print nonexistIDX
		problem+=1
		problemStr+="S_ij\r"
	ENDIF
	IF (!MPaux_checkwavesfromlist(concatList_Sij95))
		Wave nonexistIDX
		print nonexistIDX
		problem+=2
		problemStr+="S_ij95\r"
	ENDIF
	IF (!MPaux_checkwavesfromlist(concatList_mass))
		Wave nonexistIDX
		print nonexistIDX
		problem +=4
		problemStr+="signalOfClass\r"
	ENDIF
	IF (!MPaux_checkwavesfromlist(concatList_points))
		Wave nonexistIDX
		print nonexistIDX
		problem +=8
		problemStr+="pointsInClass\r"
	ENDIF
	
	// no problem
	IF (problem==0)
		//concatenate if all waves exist
		concatenate /NP/O concatList_Sij, Sij_SG_all
		concatenate /NP/O concatList_Sij95, Sij95_SG_all
		concatenate /NP/O concatList_mass, mass_SG_all
		concatenate /NP/O concatList_points, points_all
		
		// create PL error panel
		MPprep_PLE_PLErr_Panel_main("root:APP:SG_err",Wavenames)
	
	ELSE
		// some waves not found
		abortStr= "MPprep_DoSGErr():\r\rmissing waves of type: "+problemStr
		abortStr+="\rCannot proceed with PL error calculation.\rCheck MPprep_DoSGErr() procedure in debugger"
		MPaux_abort(AbortStr)
	ENDIF
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	calculate errors following the Yan et al. method using Savitzky-Golay smoothing
//				operates on single thermogram scan folders
//				
// Input:		expFolder:		String name of data folder to operate on
//				wavenames:		txt wave with name of waves (msdata,mserr,exactMZ,ionlabel,Tdesorp)
// 				SaveHisto:		1: keep histogram waves
//
// Output:	MSdata_res:		1D wave with residual for all ions (between MSdata and MSdata smooth)
//				msdata:			1D wave of MSdata
//
//				SignalOfClasses:	average signal for each % range class
//				paramsHist:		fit parameters and 95 percentile from gauss fit to histograms
// 				stdevWave			stdev of all residuals for each ion
//				maxValue			maximum of each ion thermogram
//				S_ij:				width of histograms (= total error)
//				S_ij95				95 percentile of S_ij (from gauss fit)
// called by: MPprep_DoSGErr() or stand-alone

FUNCTION MPprep_SG_error4PMF(expFolder,wavenames,SaveHisto)

String expFolder	//fill folder path
Wave/T wavenames
Variable SaveHisto

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// get data wave
String CurrentFolder="root:"+expFolder
Currentfolder=replaceString("root:root:",currentfolder,"root:")
	
Setdatafolder $Currentfolder

Wave MSdata=$wavenames[%MSdataname]

// check if MSdata exists
IF (!Waveexists(MSdata))
	abortStr="MPprep_SG_error4PMF():\r\rno MSdata wave: "+wavenames[%MSdataname]+" found in folder: "+Currentfolder
	MPaux_abort(AbortStr)
ENDIF

Newdatafolder/S/O :SG_err

// variables
Variable num1=4		// polynom type
Variable num2=35		// window size

Variable ii
Variable test=0, amplitude=30
Variable endPoint=dimsize(MSdata,0)-1	// index value for last point in wave
Variable endLength=20	// how many datapoints from end to use (usually 10 or 20)
String Smoothstr="Smoothed with polynom "+num2str(num1)+" interval size "+num2str(num2)+" for peaks height < "+num2str(amplitude)

// Make new waves
Duplicate/O MSdata,MSdata_Smooth,MSdata_res

Make/FREE/D/O/N=(dimsize(MSdata,0)) tempRes,tempData,tempSmooth
Make/D/O/N=(dimsize(MSdata,1)) stdevWave, maxValue,stdevWave_end,stdevWave_LTmean
Make/D/FREE/N=(dimsize(MSdata,1))EndAvgValue,AvgValue,MediValue

Note stdevWave_end,"stdev of residual between smoothed and measured\rlast "+num2str(endLength)+" data points"
Note stdevWave,"stdev of residual between smoothed and measured\rall data points"
Note stdevWave_LTmean,"stdev of residual between smoothed and measured\ronly for data points smaller than median of each ion"

// loop through ions to get stdev(res(raw-smooth))
FOR (ii=0;ii<dimsize(MSdata,1);ii+=1)
	
	tempData=MSdata[p][ii]
	tempSmooth=tempData
	
	// do smoothing	
	wavestats/Q tempData
	MaxValue[ii]=V_max
	AvgValue[ii]=V_avg
	
	Wavestats/Q/R=[endPoint-endLength,endpoint] tempData
	EndAvgValue[ii]=V_avg
	
	MediValue[ii]=median(tempData)
	IF (MediValue[ii]==0)	// catch if median value is 0
		MediValue[ii]=mean(tempData)/2
	ENDIF
	IF (WaveMax(tempData)>amplitude)
		// for high peaks: least amount of smoothing
		num2=17
		num1=2
		IF (test==0)
			Smoothstr+="\rSmoothed with polynom "+num2str(num1)+" interval size "+num2str(num2)+" for peaks height > "+num2str(amplitude)
			test=1
		ENDIF
	
	ENDIF
	
	// handle NaNs in input
	IF (numtype(sum(tempSmooth))!=0)	// check if at least 1 NaN is there
		// make index waves for sorting
		Make/FREE/D/N=(numpnts(tempSmooth)) SortingIDX_time,SortingIDX_NaN
		SortingIDX_time=p
		SortingIDX_NaN= numtype(tempSmooth[p])!=0? nan : SortingIDX_time[p]	// set NaN in index wave

		// sort to get nan at the end but still have "right " order
		Sort SortingIDX_NaN,SortingIDX_NaN,SortingIDX_time,tempSmooth	// sort both waves to move NaN to end

	ENDIF
	
	// do the smoothing !!! SG smoothing does not handle NaN very well -> ceates gaps in the smoothed data
	Smooth/S=(num1) num2, tempSmooth
	
	// back to normal order in case that there were NaNs
	IF (numtype(sum(tempSmooth))!=0)	// check if at least 1 NaN is there
		Sort SortingIDX_time,SortingIDX_time,tempSmooth
	ENDIF
	
	msdata_smooth[][ii]=tempSmooth[p]
	
	// get "residual"
	tempRes=tempData-tempSmooth
	MSdata_res[][ii]=tempRes[p]
	
	// stdev of res
	StdevWave[ii]=sqrt(variance(TempRes))
	
	stdevWave_end[ii]=sqrt(variance(TempRes,endPoint-endLength,endpoint))
	
	// get residual only for data points with smoothed value smaller than median
	Extract/FREE tempRes,TempRes_LTmean,tempSmooth<=AvgValue[ii]
	
	stdevWave_LTmean[ii]=sqrt(variance(TempRes_LTmean))
	
ENDFOR	// loop through ions

// get sigma noise
Make/O/D/N=6 sigma_noise
String noteStr="sigma noise for each sample"
noteStr+="\rmedian of all values\rmedian of all values with avg signal<2\rmedian of all values at last 20 data points"
noteStr+="\rmedian of all values at last 20 data points with avg signal <2\rmedian of all values calcualted with <median condition"
noteStr+="\rmedian of all values calcualted with <median condition with avg signal <2"
Note sigma_noise,noteStr

Variable test_LT2

sigma_noise[0]=median(stdevWave)
extract/FREE stdevWave, tempStdev, AvgValue<2	// if not enough datapoints with avg< 2 -> use full range
IF (numpnts(tempStdev)>10)
	sigma_noise[1]=median(tempStdev)
ELSE
	sigma_noise[1]=sigma_noise[0]
	test_LT2+=1
ENDIF

// only end points
sigma_noise[2]=median(stdevWave_end)
extract/FREE stdevWave_end, tempStdev, EndAvgValue<2
IF (numpnts(tempStdev)>10)
	sigma_noise[3]=median(tempStdev)
ELSE
	sigma_noise[3]=sigma_noise[2]
	test_LT2+=1
ENDIF

// < median values
sigma_noise[4]=median(stdevWave_LTmean)
extract/FREE stdevWave_LTmean, tempStdev, EndAvgValue<2
IF (numpnts(tempStdev)>10)
	sigma_noise[5]=median(tempStdev)
ELSE
	sigma_noise[5]=sigma_noise[4]
	test_LT2+=1
ENDIF

IF (test_LT2>0)
	print "\t\tsigma noise calculation: less than 10 ions with average signal < 2 -> using all data points for sample: "+expFolder
ENDIF

Note MSdata_Smooth,Smoothstr

// create 1D waves for extraction
Duplicate/O/FREE MSdata, MSdata1D
Duplicate/O/FREE MSdata_res,MSdata_Res1D
Redimension/N=(dimsize(msdata,0)*dimsize(msdata,1)) MSdata_res1D,MSdata1D

// make histograms
MPprep_make_histClasses(MSdata1D,MSdata_res1D,saveHisto,expFolder)

Killwaves/Z SortingIDX_time,SortingIDX_NaN,MSdata1D,MSdata_res1D
END

//======================================================================================
//======================================================================================

// Purpose:		calculate histogram classes for SG_error4PMF_APP()
//					then fit gaussian to histograms and report halfwidth as Sij
//				
// Input:			MSdata1D:			1D wave of MSdata values
//					MSdata_res1D:	1D wave of residual values (=MSdata- MSdataSmooth)
// 					saveHisto:		1: keep histogram waves
//					folderName		name of current datafolder (only for error reporting)
//
// Output:		SignalOfClasses:	average signal for each % range class
//					paramsHist:		fit parameters and 95 percentile from gauss fit to histograms
// 					stdevWave			stdev of all residuals for each ion
//					maxValue			maximum of each ion thermogram
//					S_ij:				width of histograms (= fitted total error)
//					S_ij95	:			95 percentile of S_ij (from gauss fit)
//					binEdges:			binedges of histogram classes
// called by:	MPprep_DoSGerror() -> MPprep_SG_error4PMF()


FUNCTION MPprep_make_histClasses(MSdata1D,MSdata_res1D,saveHisto,folderName)


Wave MSdata1D,MSdata_res1D
Variable saveHisto
String FOlderName

// make subwaves for HIST
Wavestats/Q/M=1 MSdata1D
Variable maxi=V_max

Make/D/O/N=(12,2) binEdges=0	// edges of the classes
Make/FREE/D/N=(dimsize(MSdata1D,0)/100,12)	 binIDX	// matrix with index values of each class in each column

// calculate borders for classes in log space
IF (numtype(maxi)==0)

	binEdges[][]=(p-1+q)*log(maxi)/11
	binedges=10^(binedges)	
	binEdges[0][0]=0

	Note binEdges, "edges of the classes for the histograms"

ENDIF

// check if almost all points are in first class
Extract/INDX/FREE MSdata1D,tempIDX, MSdata1D>binEdges[0][0] && MSdata1D<=binEdges[0][1] 

IF (numpnts(tempIDX)>0.75*numpnts(MSdata1D))
	String alertStr="PL error calc:\r\rOver 75% of all data points are grouped into first histogram class for sample:"
	alertStr+="\r"+folderName
	alertStr+="\rRecalculate bin edges?"
	DoAlert/T="PLerror calc" 2,alertStr
	
	IF (V_flag==3)	// cancel
		print "\t+ PL error calc: >75% of all data points are in first histogram class for sample: "
		print "\t\t"+folderName
		print "\t\t-> User canceled"

		ABORT
	ENDIF
	
	IF (V_flag==2)	// NO
		// do nothing
	ENDIF
	
	IF (V_flag==1)	// YES -> recalcualte bin edges
		// casue 1: All values are <<1 
		// -> scale up to have median value at 10
		Variable Medi= median(MSdata1D)
		Variable Scalingfactor=10/medi
			
		binEdges[][]=(p-1+q)*log(maxi*ScalingFactor)/11
		binedges=10^(binedges)	/scalingFactor
		binEdges[0][0]=0
			
	ENDIF

ENDIF
	

// waves for results from histograms
Make/D/O/N=(12,8) ParamsHist	// fit parameters
Note ParamsHist, "gauss fit to histogram of residuals\ryoffset;amplitude;xoffset;width; 95 percentile of params"
Make/D/O/N=(12) SignalOfClasses,S_ij,S_ij95,pointsInClass=NaN

Note SignalOfClasses,"average signal strength of histogram classes"
Note S_ij, "fitted error of class = halfwidth of histogram"
Note S_ij95, "95% confidence of S_ij"
Note pointsInClass, "number of data points in each class"

// loop through classes
Variable hh

debuggerOptions
Variable debugOnError_setting=V_debugonerror

FOR (hh=0;hh<12;hh+=1)
	
	Make/O/n=1 $("hist_"+num2Str(hh))
	Wave tempHist=$("hist_"+num2Str(hh))
	
	// get the current class
	Extract/INDX/FREE MSdata1D,tempIDX, MSdata1D>binEdges[hh][0] && MSdata1D<=binEdges[hh][1] 
	
	// check if almost all points are in 1 class
	IF (numpnts(tempIDX)>0.75*numpnts(MSdata1D))
		print "+ PL error calc: 75% of all data points are in one histogram class for sample: "
		print "\t\t\t"+folderName
		print "\t\t\tcheck input data before using fitted values for PLerror calculations"
	ENDIF
	
	IF (numpnts(tempIDX)>0)	// only do rest if at leas 1 point
		pointsInClass[hh]=numpnts(tempIDX)	// how many data points fall into the class
	
		// make histogramm
		MAKE/O/D/N=(numpnts(tempIDX))$("res_"+num2Str(hh)) 
		Wave tempRes4Hist=$("res_"+num2Str(hh))
		tempRes4Hist=msdata_res1D[tempIDX[p]]
		
		MAKE/O/D/N=(numpnts(tempIDX)) $("ms_"+num2Str(hh)) 
		Wave tempMS4Hist=$("ms_"+num2Str(hh))
		tempMS4Hist=msdata1D[tempIDX[p]]
		
		Make/FREE/D/O/N=4 TempParamsHist,TempSigma
		
		// make the actual Histogram
		IF (numpnts(tempRes4Hist)<5e4)
			// /B=5 is more robust but not good for super large waves
			histogram/C/B=5/dest=tempHist tempRes4Hist,tempHist	
		ELSE
			histogram/C/B=4/dest=tempHist tempRes4Hist,tempHist	
		ENDIF	
		// fit each histogram 
		ParamsHist[0] = 0
		IF (numpnts(tempHist)>5)	// check for enough datapoints
	
			TRY
				DebuggerOptions debugOnError=0	// turn off debug window
				CurveFit/Q/X=1/H="1000"/TBOX=784 gauss kwCWave=tempParamsHist, tempHist /F={0.95,4};AbortOnRTE
				DebuggerOptions debugOnError=debugOnError_setting	// turn off debug window
				
				Wave W_ParamConfidenceInterval
				
				//store parameters
				ParamsHist[hh][0,3]=tempParamsHist[q]	//gauss fit to histogram
				ParamsHist[hh][4,7]=W_ParamConfidenceInterval[q-4]		// 95 percentile range for parameters
			CATCH
				
				DebuggerOptions debugOnError=debugOnError_setting	// turn off debug window
				
				// set to Nan if no fit was done
				ParamsHist[hh][0,3]=NaN
				ParamsHist[hh][4,7]=Nan
	
			ENDTRY
			
		ELSE
			// set to Nan if no fit was done
			ParamsHist[hh][0,3]=NaN
			ParamsHist[hh][4,7]=Nan
		
		ENDIF
		
		//average signal for groups
		SignalOfClasses[hh]=mean(tempMS4hist)

	ENDIF
	
	// store data
	IF (saveHisto==0)
		Killwaves/Z tempHist
	ENDIF
	
	Killwaves/Z tempRes4Hist,tempIDX,tempMS4Hist
	
ENDFOR

S_ij=paramsHist[p][3]
S_ij95=paramsHist[p][7]

// clean up data
// negative values are not real
S_ij = S_ij[p] <= 0 ? NaN : S_ij[p]

// remove points with <20 signal points in class
S_ij = pointsInClass[p] < 20 ? NaN : S_ij[p]

// remove where S_ij95 > 0.75*S_ij
S_ij = S_ij95[p] > 0.75*S_ij[p] ? NaN : S_ij[p]

S_ij95 = numtype(S_ij[p]) !=0 ? NaN : S_ij95[p]


Killwaves/Z  W_paramConfidenceInterval, W_sigma

END



//======================================================================================
//======================================================================================

// Purpose: 		duplicate data waves and remove selected ions
//					remove ion idx is used to avoid issues
// Input:			folderName	: name of data folder with waves
//					suffix			:	string suffix to use for new waves
//					wavenames		:	text wave with Waves to work on
//					removeIons_idx	: 0/1 flag wave for removal

// Output:		duplicates of Data waves with selected ions removed	
// called by: 	Step1_button_control() -> but_removeIons_doit or standalone	

FUNCTION MPprep_removeIons(folderName,suffix,Wavenames,removeIons_IDX)

String folderName
String suffix

Wave/T wavenames
Wave RemoveIons_IDX

// get abort string for reporting
SVAR abortStr=root:app:abortStr
IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// check ionlabel vs removal IDX (sanity check was done at upper level)
String folderPath=folderName+":"
folderPath=replacestring("::",folderPath,":")

Wave/T ionLabel_old=$(folderpath+wavenames[%LabelName])

IF (numpnts(ionLabel_old)!=numpnts(removeIons_idx))
	abortStr="MPprep_removeIons():\r\rlength of ionLabel wave ("+num2str(numpnts(ionLabel_old))+") and removeIons_idx ("+num2str(numpnts(removeIons_idx))+") wave do not agree"
	MPaux_abort(abortStr)
ENDIF

// make new names
Duplicate/FREE/T wavenames,newNames
Newnames+=suffix

// check length of wavenames
// label
NewNames[%labelName]=MPaux_checkNameLength(NewNames[%labelName])
IF (Stringmatch(NewNames[%labelName],""))// check for still too long
	abortStr="MPprep_removeIons():\r\rNew Ionlabel wavename is too long and user could not fix it -> aborting"
	MPaux_abort(abortStr)
ENDIF
IF (StringMatch(NewNames[%labelName],Wavenames[%labelName]))	// check for identical (if user simply removed suffix
	abortStr="MPprep_removeIons():\r\rNew Ionlabel wavename is identical to original name -> aborting"
	MPaux_abort(abortStr)
ENDIF

// MZ
NewNames[%MZName]=MPaux_checkNameLength(NewNames[%MZName])
IF (Stringmatch(NewNames[%MZName],""))// check for still too long
	abortStr="MPprep_removeIons():\r\rNew MZ wavename is too long and user could not fix it. -> aborting"
	MPaux_abort(abortStr)
ENDIF
IF (StringMatch(NewNames[%MZName],Wavenames[%MZName]))	// check for identical (if user simply removed suffix
	abortStr="MPprep_removeIons():\r\rNew MZ wavename is identical to original name -> aborting"
	MPaux_abort(abortStr)
ENDIF

//MSdata
NewNames[%MSdataName]=MPaux_checkNameLength(NewNames[%MSdataName])
IF (Stringmatch(NewNames[%MSdataName],""))	// check for still too long
	abortStr="MPprep_removeIons():\r\rNew wavename is too long and user could not fix it."
	MPaux_abort(abortStr)
ENDIF
IF (StringMatch(NewNames[%MSdataName],Wavenames[%MSdataName]))	// check for identical (if user simply removed suffix
	abortStr="MPprep_removeIons():\r\rNew MSdata wavename is identical to original name -> aborting"
	MPaux_abort(abortStr)
ENDIF


// label
Make/T/O/N=(numpnts(ionLabel_old)) $(folderpath+NewNames[%labelName])
WAve/T ionlabel_new=$(folderpath+NewNames[%labelName])
ionlabel_new=ionlabel_old
//MZ
Wave exactMZ_old=$(folderpath+Wavenames[%MZName])
Make/D/O/N=(numpnts(ionLabel_old)) $(folderpath+NewNames[%MZName])
Wave exactMZ_new=$(folderpath+NewNames[%MZName])
exactMZ_new=exactMZ_old
//MSdata
Wave MSdata_old=$(folderpath+Wavenames[%MSdataName])
Make/D/O/N=(dimsize(MSdata_old,0),dimsize(MSdata_old,1)) $(folderpath+NewNames[%MSdataName])
Wave MSdata_new=$(folderpath+NewNames[%MSdataName])
MSdata_new=MSdata_old
//MSerr
Variable errorTest=0
IF (FindDimlabel(Wavenames,0,"MSerrname")>-1)	// check for MSerror entry
	errorTest=1
	
	// check wave name
	NewNames[%MSerrName]=MPaux_checkNameLength(NewNames[%MSerrName])
	IF (Stringmatch(NewNames[%MSerrName],""))
		abortStr="MPprep_removeIons():\r\rNew MSerr wavename is too long and user could not fix it -> aborting"
		MPaux_abort(abortStr)
	ENDIF
	IF (StringMatch(NewNames[%MSerrName],Wavenames[%MSerrName]))	// check for identical (if user simply removed suffix
		abortStr="MPprep_removeIons():\r\rNew MSerr wavename is identical to original name -> aborting"
		MPaux_abort(abortStr)
	ENDIF

	// make wave
	Wave MSerr_old=$(folderpath+Wavenames[%MSerrName])
	Make/D/O/N=(dimsize(MSerr_old,0),dimsize(MSerr_old,1)) $(folderpath+NewNames[%MSerrName])
	Wave MSerr_new=$(folderpath+NewNames[%MSerrName])
	MSerr_new=MSerr_old
ENDIF

// do removal
Extract/FREE/INDX removeions_idx, IDX, removeions_idx==1
Variable ii
String removedIons=""

FOR (ii=numpnts(idx)-1;ii>-1;ii-=1)
		
	Deletepoints/M=1	 IDX[ii],1, MSdata_new	// MSdata
	IF (errorTest==1)
		Deletepoints/M=1	 IDX[ii],1, MSerr_new	//MSerr
	ENDIF
	
	Deletepoints IDX[ii],1, ionlabel_new,exactMZ_new
	
	// store names for history
	removedIons+=ionLabel_old[IDX[ii]]+";"
ENDFOR

// check with user to change names in Panel
String noteStr=num2str(numpnts(IDX))+" ions were removed from these waves:\r"
noteStr+="\r"+Wavenames[%MSdataName]
noteStr+="\r"+Wavenames[%MZName]
noteStr+="\r"+Wavenames[%labelName]	
IF (errorTest==1)
	noteStr+="\r"+Wavenames[%MSerrName]
ENDIF
noteStr+="\r\rswitch Panel names to new waves?"

Doalert/T="Remove ions",1, noteStr

IF (V_flag==1)
	//YES
	Wave/T/Z PanelNames=root:APP:DataWaveNames
	
	IF (waveexists(Panelnames))	// catch if standalone and no wave present
		PanelNames[%MSdataName]=newNames[%MSdataName]
		PanelNames[%MZName]=newNames[%MZName]
		PanelNames[%labelName]=newNames[%labelName]
		IF (errorTest==1)
			PanelNames[%MSerrName]=newNames[%MSerrName]
		ENDIF
	ENDIF
ENDIF

// print info to history
print "----------------------"
print date() +" "+ time() + ": ions removed from data set"
print "new wavenames:"
print Newnames[%MSdataName]
print Newnames[%MZName]
print Newnames[%labelName]
IF (errorTest==1)
	print Newnames[%MSerrName]
ENDIF
print "total number of removed ions: "+num2Str(numpnts(idx))
print "removed ions:"
print removedions

END

//======================================================================================
//======================================================================================

// Purpose:		split "combi" data into samples to use the prep steps (e.g. error calc)
//					this is mainly  for loading txt files containing multiple FIGAERO samples
//					if no Mserr wave is found, it will be skipped

// Input:			combiName_str:	name of folder with 
//					idxWave:			Wave with start&end idx for scans
//					folderNames:		text Wave with names of data folders for samples
//					Wavenames:		text wave with names of data waves
//										to use entries from FitPET panel: root:app:Datawavenames
//										order MUST be: MSdata, Mserr,
// Output:		data is sorted into sample folders
//
// called by:	Step1_button_control() -> but_splitLoadedDAta or standalone

FUNCTION MPaux_splitCombiData(combiName_str,folderNames,idxWave,Wavenames)

String combiName_str
Wave/T folderNames
Wave idxWave
Wave/T Wavenames

String oldFolder=getdatafolder(1)

// get abortStr for reporting
SVAR abortStr=root:app:abortStr
IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// basic checks
// check for combi data folder
IF(!datafolderexists(combiName_str))	
	abortStr="MPaux_splitCombiData():\r\rcannot find folder:\r\r"+combiName_str
	MPaux_abort(AbortStr)
ENDIF

// check wavelength
IF(dimsize(idxWave,1)!=2)
	abortStr="MPaux_splitCombiData():\r\ridxWave must be 2 columns with start and end rows numbers for each sample in data set"
	MPaux_abort(AbortStr)
ENDIF

IF (dimsize(idxWave,0) != numpnts(FolderNames))
	abortStr="MPaux_splitCombiData():\r\rnumber of rows in idxWave and FolderNames wave do not match\r"+getWavesdatafolder(idxWave,2)+"\r"+getWavesdatafolder(Wavenames,2)
	MPaux_abort(AbortStr)
ENDIF

IF (numpnts(Wavenames)<6)
	abortStr="MPaux_splitCombiData():\r\rWavenames wave must contain 6 elements with the order: MSdata, MSerr, ion mass (numeric), ion labels (text), time or Tdesorp"
	MPaux_abort(AbortStr)
ENDIF

// check if Wavenames wave has Labels
IF (!Stringmatch(GetdimLabel(Wavenames,0,0),"MSdataName"))	// check if first label is empty
	print "dimension labels are wrong for Wavenames Wave -> adding default dimension labels"
	Setdimlabel 0,0, MsdataName,Wavenames
	Setdimlabel 0,1, MsErrName,Wavenames
	Setdimlabel 0,2, MZName,Wavenames
	Setdimlabel 0,3, LabelName,Wavenames
	Setdimlabel 0,4, TName,Wavenames	
	Setdimlabel 0,5, FIGTimeName,Wavenames	
ENDIF

// check for empty MSerr field
//MPaux_checkMSerrName(Wavenames)

//// if no Mserr Wave -> make dummy for checkPMFWaves()
//IF (!Waveexists($(combiName_str+":"+Wavenames[%MSerrName])))
//	Duplicate $(combiName_str+":"+Wavenames[%MSdataName]),$(combiName_str+":"+Wavenames[%MSerrName])
//	Wave MSerr=$(combiName_str+":"+Wavenames[%MSerrName])
//	Mserr=1
//ENDIF

// check for Wavenames waves in combiName_str folder
MPaux_checkPMFWaves(combiName_str,waveNames,1,ignoreErr=1)

//---------------------------------------------------

// loop parameters
Variable nos=numpnts(FolderNames)
Variable ff,ww
Variable Length
Variable test=0
Variable test1=0	// test for length
Variable test2=0	// test for illegal characters

// check names in Explist
String abortStr1="MPaux_splitCombiData():\r\rFolder names too long in Wave:"
abortSTr1+="\r"+getWavesDataFolder(folderNames,2)
String abortStr2="MPaux_splitCombiData():\r\rIllegal names detected in Wave:"
abortSTr2+="\r"+getWavesDataFolder(folderNames,2)

Variable MaxLength=254
IF (IgorVersion()<8.0)
	MaxLength=31
ENDIF

FOR(ff=0;ff<nos;ff+=1)	// check each Exp folder name
	IF (Strlen(folderNames[ff])>maxLength)
		abortSTr1+="\rrow: "+num2Str(ff)+" "+num2Str(Strlen(folderNames[ff]))+"bytes"
		test1+=1
	ENDIF
	
	IF(!stringmatch(cleanupName(folderNames[ff],0),folderNames[ff]))
		abortSTr2+="\rrow: "+num2Str(ff)+" "+folderNames[ff]
		test2+=1
	ENDIF
ENDFOR

// problem with length
IF(test1>0)
	abortSTr+=abortStr1
	MPaux_abort(abortSTr)
ENDIF

// prblem with illegal characters
IF(test2>0)
	abortSTr+=abortStr2
	MPaux_abort(abortSTr)
ENDIF
// reset abortSTr
abortSTr=""

// loop through samples

FOR (ff=0;ff<nos;ff+=1)

	String currentFolder=""
	String MissingWaves=""
	
	currentFolder="root:"+folderNames[ff]
	currentfolder=replacestring("root:root:",currentfolder,"root:")

	String CurrentWaveName=""
	
	// length of sample
	Length=idxWave[ff][1]-idxWave[ff][0]+1
	
	IF (length>0)
		// write warning if very short sample
		IF (length<30)
			print "WARNING: less than 30 data points in sample #"+num2str(ff)
		ENDIF
		
		// make data folder
		MPaux_newsubfolder(currentfolder,0)
		
		// loop through waves
		
		
		FOR (ww=0;ww<numpnts(Wavenames);ww+=1)
			
			// copy data chunks
			IF (ww==2)
			 
				// ion mass
				Wave/Z oldWave=$(combiName_str+":"+Wavenames[ww])
				duplicate/O oldWave,$(currentfolder+":"+Wavenames[ww])
				
			ELSEIF (ww==3)
				
				// ion labels
				Wave/Z/T oldWave_T=$(combiName_str+":"+Wavenames[ww])
				duplicate/O/T oldWave_T,$(currentfolder+":"+Wavenames[ww])
		
			ELSE
				// MS data and MSerr
				Wave/Z oldWave=$(combiName_str+":"+Wavenames[ww])
				
				IF (waveexists(oldWave))	// catch if MSerr or Fig time series do not exist
					
					duplicate/O/RMD=[idxWave[ff][0],idxWave[ff][1]] oldWave,$(currentfolder+":"+Wavenames[ww])
				ELSE
					MissingWaves+=num2Str(ww)+";"
				ENDIF
				
			ENDIF
			
		ENDFOR
	
	ELSE
		print "sample "+num2str(ff)+": no data points found from idxWave entries -> check idxWave"
		test+=1
	ENDIF

	
ENDFOR

// no valid sample data found for any folder
IF (test==nos)
	abortStr="MPaux_splitCombiData():\r\rproblem with idXWave values: none of the entries had a positive numebr of data points"
	MPaux_abort(AbortStr)
ENDIF

print "---------------------"
print date() + " " + time() +" splitting data set into multiple samples. Check SampleList Wave: "+NameOfWave(folderNames)
// if some waves were not there
IF (Itemsinlist(MissingWaves)>0)
	print "\t+ the following waves types were not copied to the new sample folders:"
	FOR(ff=0;ff<(itemsinlist(MissingWaves));ff+=1)
		Variable idx=str2num(Stringfromlist(ff,MissingWaves))
		print "\t\t\t- "+GetDimLabel(WaveNames,0,idx)+":\t"+Wavenames[idx]
	ENDFOR
	print "\t check names in MaS-PET Panel if these waves should have been copied."
ENDIF

// rest original folder
Setdatafolder $oldFolder

END
//======================================================================================
//======================================================================================

// Purpose:		combine separate Thermogram scans to one data set
//					optional clean up ion list (removing with a 0/1 wave or by category)
//					
// Input:			combiName: 	string name for new folder with combined data set
//					expList:		text Wave with names of folders to be combined (no root: in the name)
//					DataNames:	text wave with names for data waves (wave names must be the same in all folders used
//								order for data waves:
//								MSdata,MSerr,exactMZ,ionLabels,Tdesorp
// 					removeions:	0: do nothing, use all ions as is
//									1: remove standard ions (see list below -> no longer done in MaSPET)
//									2: remove ions using removeIdx wave (needs to be passed)
//									3: create both all and cleaned up using option 1
//									4: create both all and cleaned up using option 4
//					[removeIdx]:	wave with 1/0 for all ions, 1 means remove this ion from combi data set
//
// Output:		new folder with combiName contianing combined data
//					CombiInfo:	Text Wave with info on what was combined
//					dataWaves that are moved:
//					MSdata, MSerr, Tdesorp, ionLabels, ExactMZ
// called by:	from FiT-PET panel or stand-alone


FUNCTION MPprep_MakeCombi(combiName,ExpList,DataNames,removeIons,[removeIdxWave])

String combiName		// name for combined data folder (short)
Wave/T ExpList		// contains list of datafolders to combine
Wave/T DataNames		// contains names for waves to operate on
Variable removeIons	// remove some ions befor creating combined data set
Wave removeIdxWave	// optional for removing specific ions

setdatafolder root:

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

String alertStr=""

// input check

// check combi name
// check for  multiple layers
String combiname4Test=replaceString("root:",combiname,"")

IF (Itemsinlist(combiname4Test,":")>1)
	alertStr="MPprep_MakeCombi():\r\rPET data prep panel cannot tolerate multiple subfolder levels."
	alertStr+="\rContinue (YES) with this folder name? \rAbort (NO) if you need full compatibility with PET for data preparation."
	Doalert 1,alertStr
	IF (V_flag==2)
		MPaux_abort(alertStr)
	ENDIF
ENDIF

// check for length
String NewCombiName=MPaux_folderName("root:",combiname4Test,"combi_")
IF (!Stringmatch(NewCombiName,combiName4test))
	abortStr="MPprep_MakeCombi():\r\rChosen Combi folder name is too long. Select a different Name to avoid further issues"
	abortStr+="\r"+combiname4Test+": "+num2str(strlen(combiname4Test))+" bytes"
	MPaux_abort(abortStr)
ENDIF

// catch if no removeIdxWave 
IF (paramisdefault(removeIdxWave))

	//catch if no removeIdxWave was passed but 2 or 4 were selected
	IF (removeIons==2 || removeIons==4)
		
		alertStr="User selected mode "+num2str(removeIons)+" but did not hand over a Wave 'removeIdx'.\r"
		alertStr+="Proceed with mode " +num2str(removeIons-1)+"?"
		DoAlert 1, alertStr

		IF (V_flag!=1)
			// user canceled
			abort
		ELSE	// user said ok
			removeIons=removeIons-1	// switch mode to standard removal
			
		ENDIF
		
	ENDIF
	
	// no removeIdx wave passed -> make free wave to hold index
	String FolderName="root:"+ExpList[0]
	FolderName=replaceString("root:root:",FolderName,"root:")

	Wave MS1=$(FolderName+":"+dataNames[0]) // first entry is MSdata
	Make/FREE/D/N=(dimsize(Ms1,1)) removeIdx
	
ELSE
	
	Wave removeIdx = removeIdxWave

ENDIF

IF (!waveexists(ExpList))
	abortStr="MPprep_MakeCombi():\r\rExpFolder list wave does not exist -> check input"
	MPaux_abort(abortStr)
ENDIF

//---------------------------------------------------
// basic checks
Variable ff,ww,ii,ee,check

//IF (dimsize(datanames,0)!=5)
//	abortStr="MPprep_MakeCombi():\r\rnumber of entries in DataNames wave is not 5."
//	MPaux_abort(abortStr)
//ENDIF

// check if data wave exist in all exp folders

String CheckList=""
String FullPath=""
String EmptyFields=""

Variable noi_old=0
Variable emptyTest=0

Make/FREE/T /N=(numpnts(expList)) WaveListWave=""	// wave to store string lists with wave names in each folder

FOR (ff=0;ff<numpnts(expList);ff+=1)	//folder loop
	// reset strings
	CheckList=""
	EmptyFields=""
	alertStr=""
	emptyTest=0
	
	// make string list of waves (needs full path)
	FOR (ww=0;ww<numpnts(dataNames);ww+=1)	// wave list loop
		
		// create string list for data waves
		IF (!Stringmatch(dataNames[ww],""))	// ignore empty fields
			Fullpath="root:"+ExpList[ff]+":"+dataNames[ww]+";"
	
			// check for double root:
			FullPath=replacestring("root:root:",fullPath,"root:")
			
			CheckList+=FullPath
		ELSE
			// store missing wavenames here
			EmptyFields+=num2str(ww)+";"
			emptyTest+=1
		ENDIF
	ENDFOR	// wave list loop

	// there were empty fields
	// -> ignore if it was FIGTime
	IF (EmptyTest>0)
		FOR (ii=0;ii<itemsinlist(EmptyFields);ii+=1)
			String CurrentEmptyFIeld=Stringfromlist(ii,EmptyFields)
			
			// 5:FigTime
			IF (!Stringmatch(CurrentEmptyFIeld,"5"))
				alertStr+="\r"+getDimLabel(dataNames,0,str2num(CurrentEmptyField))
			ENDIF
			
		ENDFOR
		
		IF (Strlen(alertstr)>0)
			abortStr="MPprep_MakeCombi():\r\rWave name fields in panel are empty for waves:"+alertSTr
			MPaux_abort(abortSTr)
		ENDIF
	ENDIF
	
	// store wave list in text wave
	WaveListWave[ff]= checkList
	
	// check if waves exists (ignores MSerr and FigTime if empty)
	check=MPaux_CheckWavesFromList(CheckList)
	
	// if some waves don't exists
	IF (check<1)
		abortStr="MPprep_MakeCombi():\r\rcannot find the waves named in "+GetwavesDatafolder(dataNames,2)+" in the folder "+expList[ff]+"\r"
		
		// add wavenames to abortStr
		Wave NonExistIdx
		FOR (ii=0;ii<numpnts(NonExistIDX);ii+=1)
			abortStr+="\r"+Stringfromlist(NonExistIDX[ii],CheckList)		
		ENDFOR
		
		MPaux_abort(abortStr)
	ENDIF

	// check wave dimensions
	String folderPath="root:"+ExpList[ff]+":"
	folderPath=replacestring("root:root:",folderPath,"root:")// check for double root:
		
	Wave/D MSdata=$(folderPath+dataNames[%MSdataName])
	Wave/D MSerr=$(folderPath+dataNames[%MSerrName])
	Wave/D exactMZ=$(folderPath+dataNames[%MZname])
	Wave/T ionLabels=$(folderPath+dataNames[%LabelName])
	Wave/D T_desorp=$(folderPath+dataNames[%Tname])
		
	// MSdata and MSerr
	IF (dimsize(MSdata,0) != dimsize(MSerr,0)  || dimsize(MSdata,1) != dimsize(MSerr,1))	// compare MSdata and MSerr
		abortStr="MPprep_MakeCombi():\r\rdimension of MSdata ("+dataNames[%MSdataName]+") and MSerr ("+dataNames[%MSerrName]+")waves do not agree in Folder: "+ExpList[ff]
		MPaux_abort(abortStr)
	ENDIF

	// number of ions
	IF(dimsize(MSdata,1)!=numpnts(ionLabels) || dimsize(MSdata,1)!=numpnts(exactMZ))
		abortStr="MPprep_MakeCombi():\r\rnumber of columns in MSdata wave ("+dataNames[%MSdataName]+") and ionLabels ("+dataNames[%labelName]+") or ExactMZ waves ("+dataNames[%MZname]+") does not agree."
		MPaux_abort(abortStr)
	ENDIF
	
	// number of t_desorp points
	IF(dimsize(MSdata,0)!=numpnts(t_desorp) )
		abortStr="MPprep_MakeCombi():\r\rnumber of rows in MSdata wave ("+dataNames[%MSdataName]+") and T_desorp wave ("+dataNames[%Tname]+") does not agree."
		MPaux_abort(abortStr)
	ENDIF

	// number of FigTime points if present
	IF (!StringMatch(dataNames[%FigTimeName],""))
		Wave/D FigTime=$(folderPath+dataNames[%FigTimeName])

		IF(dimsize(MSdata,0)!=numpnts(FigTime) )
			abortStr="MPprep_MakeCombi():\r\rnumber of rows in MSdata wave ("+dataNames[%MSdataName]+") and T_desorp wave ("+dataNames[%FigTimeName]+") does not agree."
			MPaux_abort(abortStr)
		ENDIF
	ENDIF
	
	// check number of ions
	IF (ff==0)
		noi_old=numpnts(ionLabels)
	ELSE
		IF (noi_old!= numpnts(ionlabels))
			abortStr ="MPprep_MakeCombi():\r\rnumber of ions in folder "+expList[ff]+" is different from folder "+ Explist[ff-1]
			MPaux_abort(abortStr)
		ENDIF
	ENDIF
	
	// check ion labels
	IF (ff==0)
		// store first set of ion labels
		make/FREE/T/N=(noi_old) labels_First=ionLabels		
	ELSE
		// check current ionlabels against first
		IF (equalWaves(labels_First,ionLabels,1)==0)
			
			// check if problem with upper/lower case
			String elementsLower="c;h;o;n;s;i;f;"	//C covers bot C and Cl
			String elementsUpper="C;H;O;N;S;I;F;"
						
			FOR (ee=0;ee<Itemsinlist(elementsLower);ee+=1)
			
				labels_First=replaceString(stringFromlist(ee,elementsLower),labels_First,stringFromlist(ee,elementsUpper))
				ionLabels=replaceString(stringFromlist(ee,elementsLower),ionLabels,stringFromlist(ee,elementsUpper))
			
			ENDFOR
			// check again
			IF (equalWaves(labels_FIrst,ionLabels,1)==0)
				abortStr="MPprep_MakeCombi():\r\rion label waves do not agree between folders:\rroot:"+ExpList[0]+ " and\rroot:"+ExpList[ff]
				MPaux_abort(abortStr)
			ENDIF
		ENDIF
	ENDIF
	
	// reset wave reference
	Wave MSdata=$("")
	Wave MSerr=$("")
	Wave exactMZ=$("")
	Wave/T ionLabels=$("")
	Wave T_desorp=$("")
	
ENDFOR	// folder loop

//---------------------------------------------------
// prepare folders and stuff -> create combi data set

print "---------------------"
print date() + " " + time() +" combining experiments to one data set:\t"+combiName

// list of ions to be always removed
//String IonList1="I-;H2OI-;H2O2I-;HO2NI-;HO3NI-;H8N4I-;O5NI-;H2O5NI-;I2-;I3-;"
String ionlist1=""	// change default setting for general MaSPET -> nothing gets removed

// make combi data folders
String pathAll="root:"+combiName
String PathClean="root:"+combiName+"_clean"

// check for double root:
pathAll=replaceString("root:root",pathAll,"root")
pathClean=replaceString("root:root",pathClean,"root")

IF (!exists(pathAll))
	newDatafolder/O $pathAll
ENDIF
IF (!exists(pathClean) && removeions >2)	// for modes 3 & 4
	newDatafolder/O $pathClean
ENDIF

// list for concat
String ListMSdata=""
String ListMSerr=""
String ListTdesorp=""
String ListFigTime=""

String MSdataName=dataNames[%MSdataname]	// name of wave with MS data
String MSerrName=dataNames[%MSerrname]
String MZname=datanames[%MZName]
String labelName=dataNames[%LabelName]
String Tname=dataNames[%Tname]

String FigTimename=dataNames[%FigTimeName]

Variable FigTimeTest=0	// 0: no FigTime wave present
IF (!stringmatch(FigTimename,""))	//check if FigTime name exists
	FigTimeTest=1
ENDIF	

// data for fixed waves
folderPath="root:"+ExpList[0]+":"
folderPath=replaceString("root:root",folderPath,"root")

Wave MZwave=$(folderPath+MZname)
Wave/T LAbelsWave=$(folderPath+labelName)

Setdatafolder $pathAll

Make/D/O/N=(numpnts(MZwave)) $MZName
Wave exactMZ=$MZName
exactMZ=MZwave

Make/T/O/N=(numpnts(MZwave)) $LabelName
Wave/T ionLabel=$labelName
ionLabel=Labelswave

Make/D/O/N=(numpnts(ExpList),2) idxSample	// Start and End index row in combined data set for each experiment

IF (removeions>2)	// do same for "clean" folder
	setdatafolder $pathClean
	Make/D/O/N=(numpnts(MZwave)) $MZName
	Wave exactMZ=$MZName
	exactMZ=MZwave
	
	Make/T/O/N=(numpnts(MZwave)) $LabelName
	Wave/T ionLabel=$labelName
	ionLabel=Labelswave
ENDIF

// go back to all ions folder
setdatafolder $(pathAll)

String dataNote="data from samples:"

// loop through Experiment list
FOR (ff=0;ff<numpnts(ExpList);ff+=1)
	
	folderPath="root:"+ExpList[ff]+":"
	folderPath=replaceString("root:root",folderPath,"root")
	
	// list of waves to concatenate
	ListMSdata+=folderPath+MSdataName+";"
	ListMSerr+=folderPath+MSerrName+";"
	ListTdesorp+=folderPath+Tname+";"
	IF (FigTimeTest==1)	//check if FigTime exists
		ListFigTime+=folderPath+FigTimename+";"	
	ENDIF	
	
	// 	idx in combi wave
	Wave temp_tdesorp=$(folderPath+Tname)
	
	IF (ff==0)
		// for first entry
		idxSample[ff][0]=0	//start
		idxSample[ff][1]=numpnts(temp_tdesorp)-1// end
	ELSE
		idxSample[ff][0]=idxSample[ff-1][1]+1
		idxSample[ff][1]=idxSample[ff][0] + numpnts(temp_tdesorp)-1
	ENDIF
	
	// Wave note entry
	dataNote+=ExpList[ff]+";"
		
ENDFOR

// make combined waves
concatenate/O/NP=0 ListMSdata, $(MSdataName)
concatenate/O/NP=0 ListMSerr, $(MSerrName)
concatenate/O/NP ListTdesorp, $(TName)

Wave MSdata=$(MSdataName)
Wave MSerr=$(MSerrName)
Wave Tdesorp=$(TName)

// add note about which data
Note MSdata,dataNote
Note MSerr,dataNote
Note Tdesorp,dataNote

note idxSample, dataNote

// check if time or Tdesorp was handed over
IF (Tdesorp[idxSample[0][0]]<3e9)
	// set temperature offset (200 C for each sample)
	FOR (ff=0;ff<numpnts(ExpList);ff+=1)
		Tdesorp[idxSample[ff][0],idxSample[ff][1]]+=ff*200
	ENDFOR
ENDIF

//check if FigTime exists
IF (FigTimeTest==1)
	concatenate/O/NP ListFigTime, $(FigTimename)
	Wave FigTime=$FigTimeName
	Note FigTime,dataNote
	SetScale d,0,0,"dat",FigTime
ENDIF


//------------------
// clean up data if requested

// we are still in pathAll folder
// for case 3 or 4 ( do al ions & clean)
// go to separate datafolder and duplciate data

IF (removeions==3 || removeIons==4)
	// go to new datafolder
	setdatafolder $pathClean
	
	//duplicate original data set
	concatenate/O/NP=0 ListMSdata, MSdata	// containing all ions
	Wave MSdata
	concatenate/O/NP=0 ListMSerr, MSerr	// containing all ions
	Wave MSerr
	
	Wave Tdesorp=$""
	duplicate/O $(pathAll+":"+Tname),$(Tname)
	Wave Tdesorp=$TName
	
	// copy unchanged waves
	Wave ExactMZ=$""
	Wave/T IonLabel=$""
	
	folderPath="root:"+ExpList[0]+":"
	folderPath=replaceString("root:root",folderPath,"root")
	
	duplicate /O $(folderPath+MZname), $MZName
	duplicate/T /O $(folderPath+labelName), $LabelName
	
	Wave/T ionlabel=$LabelName
	Wave ExactMZ=$MZname
	
ENDIF

// remove standard ions
IF (removeions==1 || removeions==3)
	// remove ions from matrix and 1D waves
	// find entries in labels
	Make/D/O/Free/N=(itemsinlist(IonList1)) LabelIDX=NaN
	
	FOR (ii=0;ii<itemsinlist(IonList1);ii+=1)
		// find ion entry
		Grep/Q/INDX/E="(?i)\\b"+Stringfromlist(ii,Ionlist1) ionlabel
		IF (V_value>0)	// entry was found
			LabelIDX[ii]=V_startParagraph
		ENDIF
	
	ENDFOR
	
	Wavetransform zapNans LabelIdx	// remove entries which are not found
	Sort LabelIdx,LabelIdx		// sort from smallest to largest
	
	// remove points starting from the back
	FOR (ii=numpnts(labelIdx)-1;ii>-1;ii-=1)
		Deletepoints /M=1 LabelIdx[ii],1,MSdata,MSerr
		Deletepoints LabelIdx[ii],1,ExactMZ,IonLabel
		
	ENDFOR

ENDIF

// remove ions with index wave
IF (removeIons==2 || removeions==4)
	
	FOR (ii=numpnts(removeIdxWave)-1;ii>-1;ii-=1)	// start et the end
	
		IF (removeIdxWave[ii]==1)	// remove if value  is 1
			Deletepoints /M=1 ii,1,MSdata,MSerr
			Deletepoints ii,1,ExactMZ,IonLabel
		ENDIF
	
	ENDFOR

ENDIF

// back to root
setdatafolder root:

END

//======================================================================================
//======================================================================================


// Purpose:	calculate SNR values for a combined data set
//				uses existing wave idxSample which contains start and end index of each sample
//				SNR=sqrt(sum(signal^2)/sum(error^2))
//				applies downweighing to error matrix
//
// Input:		folderName:	string name of folder to operate on
//				wavenames:	text wave with names of data waves (must have labels)
//				downweigh:	X/0 to apply downweighing for weak ions by factor X
//				SNR_threshold: threshold under which an ion is considered "weak" 
//
// Output:	(noNans_)MSdata_SNRwv_sample	2D wave with SNR values for each ion (row) for each sample (column)
//				(noNans_)MSerrWk					MSerr downweighed for weak ions with factor X
//				WeakIonInfo						2D wave with 1/0 to identify the periods where an ion is conisdered weak
// called by: MPbut_step2_button_Control -> but_downweigh


FUNCTION MPprep_calcSNR_CombiData(folderName, Wavenames,downweigh,SNR_threshold)

String folderName
Wave/T wavenames
Variable downweigh,SNR_threshold

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// get waves
String ErrorName=folderName+":"+Wavenames[%MSerrName]
String ErrorWkName=folderName+":"+Wavenames[%MSerrName]+"Wk"
String MSName=folderName+":"+Wavenames[%MSdataName]

String SNRname=folderName+":"+Wavenames[%MSdataName]+"_SNRwv_sample"

// check if Waves exist
IF (!Waveexists($ErrorName))
	abortStr= "MPprep_calcSNR_CombiData():\r\rWave "+errorName+" not found in folder"  + folderName
	MPaux_abort(abortStr)
ENDIF
IF (!Waveexists($MSName))
	abortStr= "MPprep_calcSNR_CombiData():\r\rWave "+MSName+" not found in folder"  + folderName
	MPaux_abort(abortStr)
ENDIF

String IdxSampleName="idxSample"
IF (stringmatch(Wavenames[%MSdataName],"noNans_*"))	// check if noNans is used
	IdxSampleName="noNans_idxSample"
ENDIF

IF (!Waveexists($(folderName+":"+IdxSampleName)))	// check for wave with index of samples
	abortStr= "MPprep_calcSNR_CombiData():\r\rWave IdxSample not found in folder: "  + folderName
	MPaux_abort(abortStr)
ENDIF

Wave MSdata=$MSname
Wave MSerr=$ErrorName
Wave IdxSample=$(folderName+":"+IdxSampleName)

//Make results wave
Variable noi = dimsize(MSdata,1)	// number of ions
Make/D/O/N=(dimsize(MSdata,0),noi) $(folderName+":weakIonInfo")	// same dimension as MSdata
Wave WeakionInfo=$(folderName+":weakIonInfo")
Note weakIonInfo,"1: ion is weak; 0: strong ion"

Make/D/O/N=(noi,dimsize(idxSample,0)) $SNRname		// SNR values per ion(rows) per sample
Wave SNRwave=$SNRname
SNRwave=0
Note SNRwave "SNR values for each ion (row) in each sample (column)"


// loop through samples in the data set

Variable ii=0
Variable StartIdx,endIdx,length

FOR (ii=0;ii<dimsize(idxSample,0);ii+=1)
	startIdx=idxSample[ii][0]	// start index of sample
	endIdx=idxSample[ii][1]	// end index of sample
	length= endidx-startIdx+1	// length of sample
	
	// get slice of data
	Make/FREE/D/N=(length,noi) signalSlice=MSdata[p+startIDx][q]
	Make/FREE/D/N=(length,noi) errorSlice=MSerr[p+startIDx][q]
	Make/FREE/D/N=(length,noi) ionInfoSlice=0
	
	Make/FREE/D/N=(noi) tempSlice, sumError2, sumSignal2
	
	// square values
	signalSlice=signalSlice^2	// square of signal
	errorSlice=errorSlice^2	//square of error
	
	// sum of square values for each ion
	WaveStats /PCST /Q signalSLice
	Wave M_Wavestats
	SumSignal2=M_wavestats[23][p]
	
	WaveStats /PCST /Q errorSLice
	Wave M_Wavestats
	SumError2=M_wavestats[23][p]

	tempSLice=sqrt(sumSignal2/sumError2)
	SNRwave[][ii]=tempSlice[p]
	
	// create 1/0 for SNR<2
	ioninfoslice = tempslice[q]<SNR_threshold ? 1:0
	weakIonInfo[startidx,endidx][]=ioninfoslice[p-startidx][q]
	
ENDFOR

// do downweighing
IF (downweigh>0)
	duplicate/O MSerr,$ErrorWkName
	Wave ErrorWk=$ErrorWkName
	
	ErrorWk = weakioninfo[p][q] == 1 ? downweigh*errorWk[p][q]:errorWk[p][q]

	// PMF panel does not copy wave note -> use original wave
	String oldNote=Note(Mserr)
	Note/K ErrorWK, oldNote+"\rweak ions downweighted by factor:" +num2str(downweigh)
	
	// change name in wavenames wave
	Wavenames[1]=Wavenames[1]+"Wk"
	
ENDIF

// print some info about how many ions are weak
Wavestats/Q/PCST Weakioninfo
Wave M_wavestats
Make/Free/D/N=(dimsize(weakioninfo,1)) SumWeakionInfo=M_wavestats[23][p]	// get sum over columns
Killwaves/Z M_Wavestats

Extract/FREE/INDX SumWeakionInfo,StrongIons , SumWeakionInfo==0	// get ions which are weak
Extract/INDX SumWeakionInfo,$(foldername+":alwaysWeakIdx") , SumWeakionInfo==dimsize(MSdata,0)	// get ions which are weak
Wave alwaysWeakIDX=$(foldername+":alwaysWeakIdx")
Note alwaysweakIDX, "row index of ions which are weak in all samples\rrefers to rows in "+MSName

print "------------------------"
print date() +" "+time()+" downweighing data:"
			
print " + "+num2str(noi-numpnts(StrongIons))+" ions out of "+num2str(noi)+ " ions are classified as weak in at least one sample"

// check for ions which are weak in all samples
print " + "+num2Str(numpnts(alwaysWeakIdx))+" ions are classified as weak in all samples -> consider removing them"

END


//======================================================================================
//======================================================================================

// Purpose:		transfer the Wavenames chosen in MaS-PET to PET
//					
// Input:			Wavenames:		text wave with names for
//					CombiFolder_STR:	sring with name of datafolder with combi data (same as in MaS-PET)
//					
//
// Output:		waves names are set in first two tabs of PET

// called by:	MPbut_step2_button_control() -> but_openPETprep


FUNCTION MPprep_TransferWavenames2PET(CombiFolder_Str,Wavenames)

Wave/T WaveNames
String CombiFolder_Str

// get rest of info

String oldFOlder=getdatafolder(1)

// check if combi datafolder exists
IF (!datafolderexists(CombiFolder_Str))
	print "MPprep_TransferWavenames2PET():provided Combi Datafolder does not exist"
	RETURN -1	// do not abort -> opens panel with default values
ENDIF

// set right data folder
String SimpleCombiName=removefromlist("root:",CombiFolder_Str,":")

setdatafolder root:
popupmenu prep_pop_pmfPrep_dataDFSel popMatch=SimpleCombiName+":"

Setdatafolder $CombiFolder_Str

// simulate clicking on datafolder (important: datafolderstring must be with ":" at end!)
pmfCalcs_popMenu_DataFolder("prep_pop_pmfPrep_dataDFSel",naN,CombiFolder_Str+":")

// reset datafolder
Setdatafolder $CombiFolder_Str

// transfer all of the wave names, set these in popmenus 
string ListOfVariables = "dataMxNm;ErrMxNm;ColDescrWvNm;ColDesTxtWvNm;RowDescrWvNm;"

Variable ii

FOR (ii = 0; ii < itemsInList(ListOfVariables); ii += 1)
	
	String CurrentVar_PET = stringFromList(ii, ListOfVariables)	// name for popmenu variable in PET
	String CurrentPopName="prep_pop_pmfPrep_"+CurrentVar_PET
	
	svar VarName_PETprep = $"root:pmf_prep_globals:"+CurrentVar_PET+"_last"
	VarName_PETprep = Wavenames[ii]
	
	// catch differnet names for Error wave
	IF(stringmatch(CurrentVar_PET, "ErrMxNm") )
		CurrentPopName="prep_pop_pmfPrep_StdDevMxNm"
	ENDIF
	
	// make popup menu display correct wave
	popupmenu $CurrentPopName,   popmatch = VarName_PETprep

	// prepare other popup menues on first run
	if(stringmatch(CurrentVar_PET, "dataMxNm") )
		// simulate using the menu  -- enables 1d waves
		gen_pop_pmfStr("prep_pop_pmfPrep_"+CurrentVar_PET,nan,VarName_PETprep)
	ENDIF
	
ENDFOR

// set names also in Run tab
pmfPrep_butt_selectPrepped2run("")

// clean up
Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

//========================================
//		Data loader panel procedures
//========================================

//======================================================================================
//======================================================================================

// Purpose:		create Load data panel to have user chose input type
//					it is linked to Wavenames in Main Panel
// Input:			all via panel
// 				
// Output:		DataLoader_Panel with:
//						+ choose file type to load
//						+ choose type of data (single dataaset/samples)
//						+ give datafolder
//						+ give names of files to load

// called by:	FiT-PET panel button


FUNCTION MPprep_DL_DataLoader_Panel()

// new subfolder
Newdatafolder/O/S root:APP:dataLoader

// set Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution=?"
Variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

// get info from main panel
WAve/T WaveNames=root:APP:DataWaveNames
SVAR abortStr=root:APP:abortStr
SVAR CombiFOlderStr=root:APP:CombiName_STR
Wave radioValues_MSType=root:APP:radioValues_MSType

NVAR MStype_VAR=root:APP:MStype_VAR 

String LabelDummy

// containers for Panel Values
//-----------------------------

// check for existing
SVAR LoadFolderName_STR=root:APP:dataloader:LoadFolderName_STR								// string with abort info

IF (!SVAR_Exists(LoadFolderName_STR))
	// create new ones
	String/G PATH_dataloader_STR="C:"
	
	// FolderName
	String/G LoadFolderName_STR=PATH_dataloader_str	// Name of folder from which data should be loaded 
	String/G IgorFolderName_STR=combifolderStr	// Name of folder in Igor where data will be loaded to 
	
	// radio button for loaded data set type
	Variable/G loadFileType_VAR=0
	Variable/G loadSampleType_VAR=1
	Variable/G loadDelimType_VAR=0
	
	String/G loadFileType_STR="ibw"
	
	String/G FileExtensions_STR="csv"	// String to change extension setting for all files
	
	Make/O/D/N=12 radioValues_loadType={1,0,0,1,0,0,0,1,0,1,0,0}	// ibw, itx,txt | comma, semicolon, tab |single, multi, other | Igor, Matlab, text
	String radioLabel="ibw;itx;txt;comma;semicolon;tab;multi;single;other;IgorSec;MatlabSec;TimeTXT;"

	Variable ii
	FOR(ii=0;ii<Itemsinlist(radioLabel);ii+=1)
		labelDummy=stringfromlist(ii,radiolabel)
		setdimlabel 0,ii,$labelDummy,radioValues_loadType
	ENDFOR
	
	// File Names (set default from TofWare)
	Make/T/O/N=(9) FileNames={"Mx_data","Mx_err","MinErr","amus","amus_txt","tseries","LastReadHeatZone1","CurrentStepType","Matrix4PMF"}
	Make/T/O/N=(9) FileExtensions="ibw"
	String/G FileLabelList="MSdata;MSerror;MinErr;IonMass;ionLabel;tseries;Tdesorp;FigaeroStatus;AMSitx;"
	
	// IF AMS/oldACSM is selected -> default is itx with all waves
	IF (MStype_VAR>=4)	// for aerosol MS
		FileNames[0,7]=""
		FileExtensions="itx"
		loadFileType_VAR=1
		radioValues_loadType[0]=0
		radioValues_loadType[1]=1
	ELSE
		// remove filename if not selected
		FileNames[8]=""
	ENDIF
	
	// remove Figaero TD only stuff
	IF (MSType_VAR!=2)
		FileNames[6,7]=""
	ENDIF
	
	FOR (ii=0;ii<itemsinlist(FileLabelList);ii+=1)
		labelDummy=Stringfromlist(ii,FileLabelList)
		setDimLabel 0,ii,$LabelDummy,FileNames
	ENDFOR
	
	// setting time format stuff
	String/G timeFormat_STR="dd.mm.yyyy hh:mm:ss"
	Variable/G timeFormat_VAR=0	// 0: Igor seconds, 1: matlab time, 2: string format

ELSE
	// use previous ones
	//strings
	SVAR PATH_dataloader_STR=root:APP:DataLoader:PATH_dataloader_STR
	SVAR LoadFolderName_STR=root:APP:DataLoader:LoadFolderName_STR
	SVAR IgorFolderName_STR=root:APP:DataLoader:IgorFolderName_STR
	SVAR loadFileType_STR=root:APP:DataLoader:loadFileType_STR
	SVAR FileExtensions_STR=root:APP:DataLoader:FileExtensions_STR
	SVAR FileLabelList=root:APP:DataLoader:FileLabelList
	SVAR timeFormat_STR=root:APP:DataLoader:timeFormat_STR

	// Variables
	NVAR loadFileType_VAR=root:APP:Dataloader:loadFileType_VAR
	NVAR loadSampleType_VAR=root:APP:Dataloader:loadSampleType_VAR
	NVAR loadDelimType_VAR=root:APP:Dataloader:loadDelimType_VAR
	NVAR timeFormat_VAR=root:APP:Dataloader:timeFormat_VAR

	// Waves
	Wave/T FileExtensions=root:APP:DataLoader:FileExtensions
	Wave/T FileNames=root:APP:DataLoader:FileNames
	Wave radioValues_loadType=root:APP:DataLoader:radioValues_loadType
	
ENDIF

// build Panel
//----------------------------------
String PanelName="DataLoader_Panel"

Killwindow/Z DataLoader_panel

NewPanel/K=1/W=(600,200,1100,690)/N=DataLoader_panel as PanelName

// boxes
GroupBox box_0 Title="",pos={7.5,5},size={490,80}
GroupBox box_1 Title="",pos={7.5,90},size={490,395}
GroupBox box_2 Title="",pos={10,352.5},size={484,77.5}
GroupBox box_3 Title="",pos={10,430},size={335,52.5}

// text
TitleBox DL_00 title="Select File Type:",pos={15,5},fstyle= 1,fsize= 14,frame=0
TitleBox DL_01 title="Delimiter:",pos={155,5},fstyle= 1,fsize= 14,frame=0
TitleBox DL_02 title="Select Data Set Type:",pos={265,5},fstyle= 1,fsize= 14,frame=0

TitleBox DL_101 title="Source Folder:",pos={15,95},fstyle= 1,fsize= 14,frame=0
TitleBox DL_102 title="Igor Folder:",pos={15,120},fstyle= 1,fsize= 14,frame=0

TitleBox DL_103 title="Input:",pos={15,155},fstyle= 1,fsize= 14,frame=0

TitleBox DL_104 title="File Names:",pos={115,155},fstyle= 1,fsize= 14,frame=0
TitleBox DL_105 title="Loaded Wave Names:",pos={345,155},fstyle= 1,fsize= 14,frame=0

TitleBox DL_6 title="MS data",pos={15,155+1*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_7 title="MS error",pos={15,155+2*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_8 title="minimum Error",pos={15,155+3*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_9 title="Ion Mass",pos={15,155+4*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_10 title="Ion Label",pos={15,155+5*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_11 title="time series",pos={15,155+6*25},fstyle= 0,fsize= 14,frame=0

TitleBox DL_12 title="FIGAERO only:",pos={15,155+8*25},fstyle= 4,fsize= 14,frame=0
TitleBox DL_13 title="desorption T",pos={15,155+9*25},fstyle= 0,fsize= 14,frame=0
TitleBox DL_14 title="Figaero Status",pos={15,155+10*25},fstyle= 0,fsize= 14,frame=0

TitleBox DL_15 title="AMS/ACSM only:",pos={15,155+11*25},fstyle= 4,fsize= 14,frame=0
TitleBox DL_16 title="AMS/ACSM itx",pos={15,155+12*25},fstyle= 0,fsize= 14,frame=0

TitleBox DL_17 title="change to:",pos={240,155},fstyle= 0,fsize= 14,frame=0

// datafolder
Setvariable VARText_LoadFolderName pos={115,95},value=LoadFolderName_STR,Title=" ",size={300,20},font="Arial",fsize=13
// browse
Button but_browseFolder,pos={430,94.5},size={60,20},title="browse",font="Arial",fstyle= 0,fsize=14,proc=MPbut_DL_DataLoad_button_control//,help={buttonHelp[%but_loadDataFromTxt]}

// Igor folder
Setvariable VARText_IgorFolderName pos={115,120},value=IgorFOlderName_STR,Title=" ",size={285,20},font="Arial",fsize=13
// overwrite without asking
CHeckbox cb_overwrite_loader title="overwrite",pos={415,120},value=1,font="Arial",fsize=14

// default file extension
SetVariable VARTXT_defaultExtension pos={305,155},value=FileExtensions_STR,disable=2,noedit=1,Title=" ",size={35,20},font="Arial",fsize=14, proc=MPprep_DL_defaultExtensionSet
	
// names for files and waves

FOR (ii=0;ii<numpnts(FileNames);ii+=1)
	String currentVarName_file= "VarTxt_"+StringFromList(ii,FileLabelList)+"_File"
	String currentVarName_ext= "VarTxt_"+StringFromList(ii,FileLabelList)+"_ext"
	String currentVarName_Wave= "VarTxt_"+StringFromList(ii,FileLabelList)+"_wave"
	
	Variable yPos=155+(ii+1)*25
	// shift FIGAERO and AMS/ACSM 
	IF(ii>5)
		ypos+=50
	ENDIF
	IF (ii>7)
		ypos+=25
	ENDIF
	
	// file names
	SetVariable $currentVarName_file pos={115,yPos},value=FileNames[ii],Title=" ",size={190,20},font="Arial",fsize=14
	// file extensions
	SetVariable $currentVarName_ext pos={305,yPos},value=FileExtensions[ii],disable=2,noedit=1,Title=" ",size={35,20},font="Arial",fsize=14
	
	//wave names
	IF (ii<numpnts(FileNames)-1)	// AMS itx is always last one
		SetVariable $currentVarName_Wave pos={345,yPos},value=_Str:"",Title=" ",size={145,20},font="Arial",fsize=14
	ENDIF
	
ENDFOR

// set values for wavenames
SetVariable VarTxt_MSdata_wave value=Wavenames[%MSdataname]
SetVariable VarTxt_MSerror_wave value=Wavenames[%MSerrname]
SetVariable VarTxt_IonMass_wave value=Wavenames[%MZname]
SetVariable VarTxt_IonLabel_wave value=Wavenames[%LabelName]

IF (radioValues_MSType[%FIGAERO_TD]==1 && radioValues_MSType[%FIGAERO]==1)	// check if FIGAERO was selected
	SetVariable VarTxt_tseries_wave value=Wavenames[%FigTimeName]
	// change default for FIGAERO
	IF (Stringmatch(Wavenames[%TName],"T_series"))
		Wavenames[%TName]="Tdesorp"
	ENDIF

ELSE 
	SetVariable VarTxt_tseries_wave value=Wavenames[%Tname]
	// change default for non FIGAERO
	IF (Stringmatch(Wavenames[%TName],"Tdesorp"))
		Wavenames[%TName]="t_series"
	ENDIF
	
ENDIF

SetVariable VarTxt_Tdesorp_wave value=Wavenames[%Tname]

SetVariable VarTxt_MinErr_wave value=_STR:"MinErr"
SetVariable VarTxt_FigaeroStatus_wave value=_STR:"FigaeroStatus"

// radio buttons
// select input file type
Checkbox radio_loadType_ibw, mode=1,pos={15,25},title="Igor binary (.ibw)",value=radioValues_loadType[%ibw],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_itx, mode=1,pos={15,45},title="Igor text (.itx)",value=radioValues_loadType[%itx],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_txt, mode=1,pos={15,65},title="delimited text",value=radioValues_loadType[%txt],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control

// select delimiter for text file load
Checkbox radio_loadType_comma, mode=1,pos={155,25},title="comma",value=radioValues_loadType[%comma],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_semicolon, mode=1,pos={155,45},title="semicolon",value=radioValues_loadType[%semicolon],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_tab, mode=1,pos={155,65},title="tab",value=radioValues_loadType[%tab],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control

// select input type (one file with multiple samples, on continuous dataset, other
Checkbox radio_loadType_single, mode=1,pos={265,25},title="single",value=radioValues_loadType[%single],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_multi, mode=1,pos={265,45},title="multi (e.g. multiple Thermograms)",value=radioValues_loadType[%multi],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_other, mode=1,pos={265,65},title="other",value=radioValues_loadType[%other],fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control

// select time format for txt load
Checkbox radio_loadType_IgorSec, mode=1,pos={115,155+7*25},title="Igor",value=radioValues_loadType[%IgorSec],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_MatlabSec, mode=1,pos={163,155+7*25},title="Matlab",value=radioValues_loadType[%MAtlabSec],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control
Checkbox radio_loadType_TimeTXT, mode=1,pos={230,155+7*25},title="string",value=radioValues_loadType[%timeTXT],disable=1,fstyle= 0,fsize= 14,frame=0,font="Arial",proc=MPbut_radio_DL_loadType_control

Setvariable VarTxt_TimeFormat,pos={290,154+7*25},size={200,20}, value=TimeFormat_STR,title=" ",disable=1,fsize= 14,font="Arial"

// load button
Button but_dataLoader,pos={440,430},size={50,50},title="Load",font="Arial",fstyle= 1,fsize=14,proc=MPbut_DL_DataLoad_button_control//,help={buttonHelp[%but_loadDataFromTxt]}

// help buttons
Button but_help_DLfiletype,pos={132,8},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control
Button but_help_DLsampletype,pos={410,8},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control
Button but_help_DLfolders,pos={96,121},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control
Button but_help_DLinput,pos={60,158},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control
Button but_help_DL_timeformat,pos={84,308},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control

// handle radio buttons settings
FOR (ii=numpnts(radioValues_loadType)-1;ii>-1;ii-=1)	// reverse order keeps time format string hidden
	IF (radioValues_loadType[ii]==1)	// if button ius checked
		String radiobutname="radio_loadType_"+Getdimlabel(radioValues_loadType,0,ii)
		
		MPbut_radio_DL_loadType_action(radiobutname)
	ENDIF
	
ENDFOR

// reset Panel resolution to default
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

END

//======================================================================================
//======================================================================================

// Purpose:		Top routine for loading data files
//					
// Input:			Overwrite:		1: overwrite existing waves without asking, 0: ask user if wave should be overwritten or give a new name
//					FileNames:		txt Wave containing names of files to be loaded (Waves without file extension)
//										empty entry -> skip this variable
//					FileExtension:	txt wave with file extensions for file names (eg ibw, itx)
//					LoadedWaveNames:	text Wave containing names for the laoded waves
//
// Output:		waves are loaded into Igor with the selected names

// called by:	MPbut_DL_DataLoad_button_control -> but_dataLoader

FUNCTION MPprep_DL_DataLoader_Main(OVerwrite,FileNames,FileExtensions,LoadedWaveNames)

Wave/T FileNames			// n=9
Wave/T LoadedWaveNames	// n=8!! AMS/ACSM is missing!!!
Wave/T Fileextensions	// n=9

Variable Overwrite

//------------------------------
//Variables and Strings from Panel

SVAR abortSTR=root:APP:abortSTr	// abort Str for error reporting
SVAR expLISt_str=root:APP:explist_str
SVAR Combiname_Str=root:app:Combiname_Str

SVAR FileLabelList =root:APP:dataloader:FileLabelList	// labels for FileNames Wave

SVAR IgorFOlder=root:APP:dataloader:IgorFolderName_STR	// string name of the folder to load to in Igor
SVAR LoadFOlder=root:APP:dataloader:LoadFolderName_STR	// String name of data folder on computer to load from

NVAR loadFileType=root:APP:dataloader:loadFileType_VAR		// 0: ibw waves, 1: itx waves, 3: delimitered text
NVAR loadSampleType=root:APP:dataloader:loadSampleType_VAR	// data set type: 0: one single "sample", 1: multiple samples (eg FIGAERO thermograms), 2: other
NVAR loadDelimType=root:APP:dataloader:loadDelimType_VAR	// 0: comma, 1: semicolon, 2: tab

NVAR MSType=root:APP:MStype_VAR	// selected mass spec type

NVAR timeFormat_VAR=root:APP:dataLoader:timeFormat_VAR	// format of time data 0: Igor seconds, 1: Matlab datenum, 2: string
SVAR timeFormat_STR=root:APP:dataLoader:timeFormat_STR	// format string for time load

// check/create Igor folder
String oldFolder=getdatafolder(1)
MPaux_NewSubfolder(IgorFOlder,0)	// only generate, don't set

// temporary stuff
Make/T/FREE/N=(numpnts(FileNames)) LoadedWaves=""

// remove extra ":" at end of loadFOlder string
LoadFOlder=removeending(loadFolder,":")

// loop through input variables
Variable ii
Variable testNum=0	// to keep track if at least 1 file was loaded
Variable refnum

Variable Test_tofware=0	// this is only an issue with tofware data export
Variable IDX_HRUMR=-3		// index for splitting HR and UMR, -3 indicates it has not been used, -2&-1 mean only one data type present
Variable WHichions=3		// 3: keep all/do nothing, 2: keep only UM, 1: keep only HR
Variable ionlabelLoaded=0	// indicate if ionLabel text file was loaded
					
String CurrentWaveName,currentFilePath
String WavePath,NewWaveName,helpStr
String WaveNote

// input variable loop							
FOR (ii=0;ii<numpnts(FileNames)-1;ii+=1)	// ! AMS&ACSM itx matrix is done separately
	
	// skip if empty
	IF (!stringmatch(FileNames[ii],""))
		testNum+=1
		
		IF (testNum==1)
			// notes to history
			print "------------------"
			print date() + " " + time() + " loading data from ."+FIleextensions[ii]+" files"
			print "+ These waves were loaded from "+LoadFOlder
		ENDIF
		
		CurrentWaveName=GetdimLabel(FileNames,0,ii)
		
		// build filename
		currentFilePath=LoadFOlder+":"+FileNames[ii]+"."+Fileextensions[ii]
		
		// fix duplicate : or .
		currentFilePath=replaceString("::",currentFilePath,":")
		currentFilePath=replaceString("..",currentFilePath,".")
	
		// check if file exists
		
		Open/R/Z=1 refnum as currentFilePath
		
		// user canceled
		IF (V_flag <0)
			print "loading aborted file not found with name: \r\r"+currentFilePath
			IF (loadFileType==2)
				print "-> check file extension in DataLoader Panel"
				print "-> check provided file name and folder"
			ENDIF
			abortSTr="MPprep_DL_DataLoader_Main():\r\rSelected File not found:\r"+currentFilePath
			Abort	
		ENDIF
		
		Close refnum
		
		// use different loading depending on file type
		SWITCH (loadFileType)
		
			//--------------------------
			CASE 0:	// ibw
				// loads same as itx
				
			CASE 1:	// itx
				// load wave to root:APP:dataloader folder
				IF (loadFileType==0)
					// ibw files
					LoadWave/O/Q currentFilePath
				ELSE
					// itx files
					Button but_dataLoader WIN=DataLoader_panel, disable=1	// deactivate button to fix issue with redrawing panels in Igor 8
					LoadWave/T/O/Q currentFilePath
					Button but_dataLoader WIN=DataLoader_panel, disable=0	// and reactivate
				ENDIF
				
				IF (Itemsinlist(S_wavenames)>1)
					abortSTR="MPprep_DL_DataLoader_Main():\r\rMore than 1 wave found in file:\r"+currentFilePath
				ENDIF
				
				// handle numeric/text waves
				IF (Stringmatch(CurrentWavename,"ionLabel"))
					// text wave (only ion label)
					Wave/T CurrentWave_T=$Stringfromlist(0,S_wavenames)
					Wave CurrentWave=$""
				ELSE
					Wave CurrentWave=$Stringfromlist(0,S_wavenames)
					Wave/T CurretnWave_T=$""
				ENDIF
				
				//"move" Wave to designated folder
					
				WavePath=IgorFOlder+":"+LoadedWaveNames[ii]
				WavePath=replaceString("::",WavePath,":")
				
				IF (Waveexists($WavePath) && overwrite==0)
					// check with user before overwriting
					NewWaveName=WavePath
					Prompt NewWaveName, "Give unique Wavename to avoid overwriting"
					HelpStr="To overwrite existing wave select Yes. Or provide a new Wave Name."
					DoPrompt/Help=helpStr "Existing Wave detected",NewWaveName
					
					IF (V_FLAG==1)	// user canceled
						print "User aborted load"
						abort
					ENDIF
					
					WavePath=NewWaveName
					
				ENDIF
							
				//------------------------------
				// handle issue with HR and UMR in one file for Tofware export
				
				// get wavenote to chekc
				IF (Waveexists(CurrentWave))
					WaveNote=Note(CurrentWave)
				ELSE
					WaveNote=Note(CurrentWave_T)
				ENDIF
					
				// check if Tofware export
				IF (Stringmatch(WaveNote,"tw_export*"))
					test_tofware+=1
					
					// ask user what to do (only with first wave)
					IF (test_tofware==1)
						String alertStr="Data was exported with Tofware and can contain both HR and UMR ions. Which ions do you want to keep?\r\r"
						alertStr+="only HR ions (YES)\r\ronly UMR ions (NO)\r\rall ions (CANCEL)"
						DoAlert,2, alertStr
						
						WhichIons=V_flag
						String IonTypeStr="x;HR ions;UMR ions;all ions;"
						print "Data from Tofware -> User chose to only import "+Stringfromlist(WhichIons,IonTypeStr)
					ENDIF
				
					// handle the HR&UMR mess for all waves contain ions (MSdata, MSerror, ionLabel, exactMZ, 
					STRSWITCH (CurrentWaveName)
						CASE "MSdata":
							IDX_HRUMR=FindDimLabel(CurrentWave,1,"0.0000000000,Total ion current")
							
							// if both HR and UMR were found
							IF (IDX_HRUMR>-1 && Whichions==1)	// use only HR
								Deletepoints/M=1 IDX_HRUMR,dimsize(CurrentWave,1)-IDX_HRUMR+1,CurrentWave
								Note/NOCR CurrentWave,"ionType:HR;"
							ENDIF
							
							IF (IDX_HRUMR>-1 && Whichions==2)	// use only UMR
								Deletepoints /M=1 0,IDX_HRUMR+1,CurrentWave
								Note/NOCR CurrentWave,"ionType:UMR;"
							ENDIF
						
							BREAK
							
						CASE "ionlabel":
							Grep/INDX/Q/E=("(?i)Total ion current") CurrentWave_T
							Wave W_index 
							IF (numpnts(W_index)>=0)
								IDX_HRUMR=W_index[0]
							ELSE
								IDX_HRUMR=-1
							ENDIF
								// if both HR and UMR were found
							IF (IDX_HRUMR>-1 && Whichions==2)	// use only UMR
								Deletepoints/M=0 0,IDX_HRUMR+1,CurrentWave_T
								Note/NOCR CurrentWave_T,"ionType:UMR;"
							ENDIF
							
							IF (IDX_HRUMR>-1 && Whichions==1)	// use only HR
								Deletepoints /M=0 IDX_HRUMR,dimsize(CurrentWave_T,0)-IDX_HRUMR+1,CurrentWave_T
								Note/NOCR CurrentWave_T,"ionType:HR;"
							ENDIF
							BREAK
							
						CASE "IonMass":
							IDX_HRUMR=FindDimLabel(CurrentWave,0,"Total ion current")
							IF (IDX_HRUMR>-1 && Whichions==2)	// use only UMR
								Deletepoints/M=0 0,IDX_HRUMR+1,CurrentWave
								Note/NOCR CurrentWave,"ionType:UMR;"
							ENDIF
							
							IF (IDX_HRUMR>-1 && Whichions==1)	// use only HR
								Deletepoints /M=0 IDX_HRUMR,dimsize(CurrentWave,0)-IDX_HRUMR+1,CurrentWave
								Note/NOCR CurrentWave,"ionType:HR;"
							ENDIF
							BREAK
							
						CASE "MSerror":
							// MS error does not have the label -> use IDX_HRUMR from previous wave
							IF (IDX_HRUMR != -3)
														// if both HR and UMR were found
								IF (IDX_HRUMR>-1 && Whichions==2)	// use only UMR
									Deletepoints/M=1 0,IDX_HRUMR+1,CurrentWave
									Note/NOCR CurrentWave,"ionType:UMR;"
								ENDIF
								
								IF (IDX_HRUMR>-1 && Whichions==1)	// use only HR
									Deletepoints /M=1 IDX_HRUMR,dimsize(CurrentWave,1)-IDX_HRUMR+1,CurrentWave
									Note/NOCR CurrentWave,"ionType:HR;"
								ENDIF
							
		
							ELSE
							
								// inform user
								print "MSerror wave was loaded on its own into folder: "+IgorFolder+".\rUnable to determine if HR and UMR ion were present"
								print "User must check wave manually before proceeding !!!"

								IF (Waveexists(CurrentWave_T))
									Note/NOCR CurrentWave_T,"ionType:all;"
								ELSE
									Note/NOCR CurrentWave,"ionType:all;"
								ENDIF
								
							ENDIF
												
							BREAK
							
						DEFAULT:
							// do nothing
							BREAK
					ENDSWITCH
					
						
				ENDIF	// wave loaded check
				
				//---------------------------------
				// copy data to the right place
				IF (Waveexists(CurrentWave_T))
					Duplicate/O CurrentWave_T,$WavePath
				ELSE
					Duplicate/O CurrentWave,$WavePath
				ENDIF
				Killwaves/Z 	CurrentWave_T,CurrentWave

				// store loaded Waves and print to history
				LoadedWaves[ii]=WavePath
				print "\t\t"+CurrentWavename+": "+WavePath
	
			BREAK
			
			//--------------------------
			
			CASE 2:	// text files (csv, txt, whatever) $$$
				
				// set loading type for numeric/text
				Variable k_set=1// force numeric
				
				// ion label is always text, force time to be loaded as text
				IF (Stringmatch(CurrentWaveName,"IonLabel") || Stringmatch(CurrentWaveName,"tseries"))
					// force text for ion Labels and time series
					k_set=2
				ENDIF
				
				// define delimiter in file
				String delimiter=","
				
				IF (LoadDelimType==1)
					delimiter=";"
				ENDIF
				IF (LoadDelimType==2)
					delimiter="\t"	// tab
				ENDIF
				
				// set dimensions of waves and load
				Variable Dimensions=1
				
				IF (Stringmatch(CurrentWaveName,"MSdata") || Stringmatch(CurrentWaveName,"MSerror")  )
					Dimensions=2
					
					// Load 2D waves (MS data & MSerr)
					LoadWave/M/O/A/W/Q/D/J/K=(k_set) /V={delimiter,"$",0,1} currentFilePAth
					
					// check if loading worked ok
					// problem with single entry for header
					Wave TestWave=$(Stringfromlist(0,S_wavenames))
					IF (dimsize(TestWave,1)==1)	// only one column
						// try loading again with first row as header
						LoadWave/M/O/A/W/Q/D/J/K=(k_set) /V={delimiter,"$",0,1}/L={0,1,0,0,0} currentFilePAth
					ENDIF
					
				ELSE
					
					// load 1D Waves
					// ion labels need special treatment if they do not have a header
					IF (Stringmatch(CurrentWaveName,"IonLabel"))	// this is the ion labels file
						// read without /W -> header would be first entry
						LoadWave/O/A/Q/D/J/K=(k_set)/V={delimiter,"$",0,1} currentFilePath
						ionlabelLoaded=1
					ELSE
						LoadWave/O/A/W/Q/D/J/K=(k_set)/V={delimiter,"$",0,1} currentFilePath
					ENDIF			
				ENDIF
				
				String NameForLoading=Stringfromlist(0,S_wavenames)
				// get loaded Wave and do basic checks
				IF (k_set==2)

					// text waves
					
					Wave/T CurrentWave_T=$NameForLoading
					Wave CurrentWave=$""
					
					// check dimensions
				
					IF (dimensions != WaveDims(CurrentWave_T))
						abortStr="MPprep_DL_DataLoader_Main():\r\rProblem loading "+CurrentWaveName+" Wave."
						abortStr+="\r"+num2str(dimensions)+"d Wave expected but loaded Wave has "+num2str(WaveDims(CurrentWave_T))+"dimension(s)."
						abortSTr+="\raborting -> check filenames and try again"
						MPaux_abort(abortStr)
					ENDIF
				
				ELSE
					// numeric waves
					Wave CurrentWave=$NameForLoading
					Wave/T CUrrentWave_T=$""
				
					// check dimensions
					IF (dimensions != WaveDims(CurrentWave))
						abortStr="MPprep_DL_DataLoader_Main():\r\rProblem loading "+CurrentWaveName+" Wave."
						abortStr+="\r"+num2str(dimensions)+"d Wave expected but loaded Wave has "+num2str(WaveDims(CurrentWave))+"dimension(s)."
						abortSTr+="\raborting -> check filenames and try again"
						MPaux_abort(abortStr)
					ENDIF
	
				ENDIF
							
				// convert time series to numeric
				IF (Stringmatch(CurrentWaveName,"tseries"))
					
					Wave/T t_series_txt=$NameForLoading
					
					Make/D/O/N=(numpnts(t_series_txt)) t_series_num
					
					Variable Typetest=0
					
					// use User input to create numeric time wave
					SWITCH (timeFormat_VAR)
						
						// using Igor time format
						CASE 0:
							t_series_num=str2num(t_series_txt)	// convert to numeric
							
							// check if it was numeric
							IF (t_series_num[1]<3000 || numtype(t_series_num[1])!=0)
								// alert User if it looks like string values were loaded
								AlertStr="User selected Igor format for time series load. But values look like Strings:"
								AlertStr+="\r"+t_series_txt[1]
								AlertStr+="\r\rData is stored as is. But check input and load again if needed."
								DoAlert 0,alertStr
								
								typeTest=1
							ENDIF
							// check if Matlab time
							IF(typetest==0 &&  (t_series_num[1]>7e5 && t_series_num[1]<5e8)	)	// 5e8 in Igor =5.11.1919 
								AlertStr="User selected Igor format for time series load. But value looks too small - could be Matlab datenum."
								AlertStr+="\rConvert to Igor format assuming matlab datenum?"
								DoAlert 1,alertStr
								
								IF (V_flag==1)	//YES -> convert to Igor
									Duplicate/FREE t_series_num,t_series_temp
									t_series_num=MPaux_Matlab2IgorTime(t_series_temp)
								ENDIF
								
							ENDIF
							
							BREAK
							
						// using Matlab time format
						CASE 1:
							t_series_num=str2num(t_series_txt)	// convert to numeric
							
							// check if it was numeric
							IF (t_series_num[1]<3000 || numtype(t_series_num[1])!=0)
								// alert User if it looks like string values were loaded
								AlertStr="User selected Matlab format for time series load. But values look like Strings:"
								AlertStr+="\r"+t_series_txt[1]
								AlertStr+="\r\rCheck input and load again if needed."
								DoAlert 0,alertStr
								
								typeTest=1
							ENDIF
							
							// // check if it is already in Igor secs
							IF(t_series_num[1]>5e8 )	
								AlertStr="User selected Matlab format for time series load. But value looks too big - could be Igor format."
								AlertStr+="\rConvert to Igor format assuming matlab datenum anyway?"
								DoAlert 1,alertStr
								
								IF (V_flag==0)	//NO -> do not convert to Igor
									typeTest=1
								ENDIF
							ENDIF
							
							
							IF (typeTest==0)	//everything ok -> convert to Igor
								Duplicate/FREE t_series_num,t_series_temp
								t_series_num=MPaux_Matlab2IgorTime(t_series_temp)
							ENDIF

							BREAK
						
						// String
						CASE 2:
							//check second row entry if it converts ok
							t_series_num[1]=MPaux_string2js(t_series_txt[1],timeFormat_STR,noabort=1)
							
							// catch if wrong format -> ask user for new format
							IF (t_series_num[1] == -999)
								String NewTimeFormat="yyyy-mm-dd hh:mm:ss"
								Prompt NewTimeFormat,"New time format ("+t_series_txt[1]+")"
								
								HelpStr="Provide a new format for loading time from text files.\r"
								HelpStr+="write 'numeric' to indicate that the time data is in numeric Igor format"
								
								DoPrompt /Help=HelpStr"Provide a string with the format of the time data", NewTimeFormat
							
								IF (V_flag==1)	// user canceled
									print "load of time series wave aborted due to incorrect format of time string"
									abort
								ENDIF
								
								// try again
								IF (Stringmatch(newTimeFormat,"Numeric"))
									t_series_num=str2num(t_series_txt)
								ELSE
									t_series_num[1]=MPaux_string2js(t_series_txt[1],NewTimeFormat,noabort=1)	
									// catch if new format is unknown to function
									IF(t_series_num[1] == -999)
										abortStr="MPprep_DL_DataLoader_Main():\r\rProvided time format not recognised by 'MPaux_string2js()'"
										abortStr+="\rCheck history window for supported time formats and try again."
										
										print "-----------"
										print "supported time string fromats:"
										print "\tdd.mm.yyyy hh:mm:ss"
										print "\thh:mm:ss dd.mm.yyyy"
										print "\tyyyy-mm-dd hh:mm:ss"
										print "\tmm/dd/yy hh:mm:ss"
										print "\thh:mm:ss dd/mm/yy"
										print "\tdd/mm/yyyy hh:mm:ss"
										print "\tm/d/yyyy hh:mm:ss AM"
										print "\tdd.mm.yyyy"
										print "\tdd/mm/yyyy"
										print "\tyyyy-mm-dd"
										print "\thh:mm:ss"
										
										MPaux_abort(abortStr)
									ENDIF
									// everything ok -> convert all
									t_series_num=MPaux_string2js(t_series_txt,NewTimeFormat,noabort=1)	
								ENDIF
							ELSE
								t_series_num=MPaux_string2js(t_series_txt,timeFormat_STR,noabort=1)
							ENDIF
				
							IF (numtype(t_series_num [1])==2)	// notify if problem
								print "problem with converting txt time values to numbers for wave: "+currentFilePath
								print "check the date/time format and use MPaux_string2js(t_series_txt,\"yourFormatString\") manually"
							ENDIF
							BREAK
							
						DEFAULT:
							BREAK
					ENDSWITCH
					
					// reset the Current wave for copying below
					Wave CurrentWave=t_series_num
					Wave/T CurrentWave_T=$""
					
					Setscale d 0,0,"dat" CurrentWave	// set to time format
				ENDIF


				//"move" Wave to designated folder
					
				WavePath=IgorFOlder+":"+LoadedWaveNames[ii]
				WavePath=replaceString("::",WavePath,":")
				
				IF (Waveexists($WavePath) && overwrite==0)
					// check with user before overwriting
					NewWaveName=WavePath
					Prompt NewWaveName, "Give unique Wavename to avoid overwriting"
					HelpStr="To overwrite existing wave select Yes. Or provide a new Wave Name."
					DoPrompt/Help=helpStr "Existing Wave detected",NewWaveName
					
					IF (V_FLAG==1)	// user canceled
						print "User aborted load"
						abort
					ENDIF
					
					WavePath=NewWaveName
					
				ENDIF

				//---------------------------------
				// copy data to the right place
				IF (Waveexists(CurrentWave_T))
					Duplicate/O CurrentWave_T,$WavePath
				ELSE
					Duplicate/O CurrentWave,$WavePath
				ENDIF
				
				Killwaves/Z 	CurrentWave_T,CurrentWave,t_series_txt

				// store loaded Waves and print to history
				LoadedWaves[ii]=WavePath
				print "\t\t"+CurrentWavename+": "+WavePath

				BREAK
			//--------------------------
				
			DEFAULT:
				BREAK
			
		ENDSWITCH
		
		
	ELSE
		// empty file name field -> do nothing
	ENDIF
	
ENDFOR	// end variable loop

// checkif IonLabel wave was loaded and needs adjusting
IF (ionlabelLoaded==1)
	
	WavePath=IgorFOlder+":"+LoadedWaveNames[4]
	WavePath=replaceString("::",WavePath,":")	
	Wave/T ionLabel=$(WavePath)

	// assume that MSdata is already loaded
	Wave/T WaveNames=root:APP:DataWavenames
	WavePath=IgorFOlder+":"+WaveNames[%MSdataName]
	WavePath=replaceString("::",WavePath,":")	
	
	Wave MSdata=$Wavepath
	
	IF (Waveexists(MSdata))
		// if ion label is 1 point longer than MSdata columns
		IF (numpnts(ionlabel)==dimsize(Msdata,1)+1)
			Deletepoints 0,1,ionLabel
		ENDIF
	ELSE
		
	ENDIF
	
ENDIF


// check if AMS itx should be loaded
Variable IDX_AMS=numpnts(FileNames)-1

IF (!stringmatch(FileNames[IDX_AMS],""))
	// notes to history
	print "------------------"
	print date() + " " + time() + " loading data from AMS/ACSM ."+Fileextensions[IDX_AMS]+" files"
	print "+ These waves were loaded from "+LoadFOlder

	testNum+=1
	
	// build file path
	currentFilePath=LoadFOlder+":"+FileNames[IDX_AMS]+"."+Fileextensions[IDX_AMS]
		
	// fix duplicate : or .
	currentFilePath=replaceString("::",currentFilePath,":")
	currentFilePath=replaceString("..",currentFilePath,".")
	
	LoadWave/T/O/Q currentFilePath
	
	IF (V_FLAG<=0)
		abortSTr="MPprep_DL_DataLoader_Main():\r\rProblem loading AMS/ACSM data from itx file. User aborted."
		MPaux_abort(abortStr)
	ENDIF
	
	// move loaded waves to IgorFOlder
	FOR (ii=0;ii<itemsinlist(S_wavenames);ii+=1)
	
		String Currentname=Stringfromlist(ii,S_Wavenames)
	
		Wave TestWave=$Currentname
		
		// catch text wavve
		IF (Wavetype(TestWave,1)==2)
			Wave/T/Z CurrentWave_T=$Currentname
			Wave/Z CurrentWave=$""
		ELSE
			Wave/T/Z CurrentWave_T=$""
			Wave/Z CurrentWave=$CurrentName
		ENDIF
	
		//"move" Wave to designated folder
		WavePath=IgorFOlder+":"+Currentname
		WavePath=replaceString("::",WavePath,":")
		
		// check if overwriting
		IF (Waveexists($WavePath) && overwrite==0)
			// check with user before overwriting
			NewWaveName=WavePath
			Prompt NewWaveName, "Give unique Wavename to avoid overwriting"
			HelpStr="To overwrite existing wave select Yes. Or provide a new Wave Name."
			DoPrompt/Help=helpStr "Existing Wave detected",NewWaveName
			
			IF (V_FLAG==1)	// user canceled
				print "User aborted load"
				abort
			ENDIF
			
			WavePath=NewWaveName
			
		ENDIF
		
		// copy data to the right place
		IF (Waveexists(CurrentWave_T))
			Duplicate/O CurrentWave_T,$WavePath
		ELSE
			Duplicate/O CurrentWave,$WavePath
		ENDIF
		Killwaves/Z 	CurrentWave_T,CurrentWave
	
		// LoadedWaves[ii]=WavePath	// issue if more thna 9 waves are loaded
		print "\t\t"+Currentname+": "+WavePath

	ENDFOR

ENDIF

//----------------------------------------------
// check if multi was selected (usually only for FIGAERO thermogram)

// file with single data set

IF (loadSampleType==1)
	
	// create expList wave and set in panel
	Make/O/T/N=1 root:APP:ExpList_Single	// I hope this does not collide with anything the user created
	Wave/T Explist=root:APP:ExpList_Single
	Explist[0]=Stringfromlist(Itemsinlist(IgorFolder,":")-1,IgorFolder,":")
	
	Explist_STR="root:APP:ExpList_Single"
	
	// set combi folder name to laoded folder
	Combiname_Str=IgorFolder
	
	// tell user what to do
	print "\r  + continuous data set loaded"
	print "New ExpList wave created and set in Panel"
	IF(mstype<4)
		// non AMS/ACSM data
		print "If MSerr matrix is present and no ions need to be removed: -> continue with Step 2"
		print "If MSerr needs to be calculated: -> use 'prep Data' button and then go to Step 2"
	ELSE
		// AMS & ACSM data
		print "check Wavenames in MaS-PET panel."
		print "Then continue with Step 2 and open PET panel."
		
	ENDIF
ENDIF

// file with multiple FIGAERO samples
IF (loadSampletype==0)
	Wave/T Wavenames=root:app:dataWavenames

	// do automatic idxSample calcultion and generate dummy ExpList Wave
	Wave Tdesorp=$(IgorFolder+":"+Wavenames[%Tname])
	IF (Waveexists(Tdesorp))
		MPaux_makeIDXsample("root:APP:IDXsample",Tdesorp)
		
		Wave IDXsample=root:APP:IDXsample
		
		// check if ExpList matches
		Variable test=0
		IF (numpnts(EXPlist)!=dimsize(idxSample,0))
			alertStr="Length of selected ExpList ("+num2Str(numpnts(ExpList))+") wave and calculated IdxSample("+num2Str(dimsize(IdxSample,0))+") wave do not agree."
			alertStr+="\rCreate matching ExpList Wave?"
			
			String NewExpList_Str=Explist_Str
			Prompt NewExpList_Str,alertStr
			DoPrompt "Create new ExpList Wave?", NewExpList_Str
			
			IF (V_FLAG==0)	// continue
				// make new ExpList wave
				Make/T/O/N=(dimsize(idxSample,0)) $(NewExpList_Str)
				Wave/T NewExpList=$NewExpList_Str
				NewExpList="TG_"+num2Str(p)
				
				// set new name in Panel
				Explist_Str=NewExpList_Str
	
				test=1
			ENDIF
								
		ENDIF
	ELSE
		AlertStr="MPprep_DL_DataLoader_Main()\r\rUser selected 'multiple samples', but unable to calculate IdxSample wave because Tdesorp wave is missing."
		AlertStr+="Load Tdesorp wave and/or provide idxSample wave maunally"
	ENDIF
	
	// display result for user to check
	Wave/T explist=$explist_str
	
	IF(Waveexists(ExpList) && Waveexists (idxSample) && Waveexists(Tdesorp))
		Killwindow/Z IDXsampleCalculation
		Edit/k=1/N=IDXsampleCalculation Tdesorp,idxSample,ExpList as "IDXsampleCalculation"
		
		print "\r  + Automatically determined idxSample values for separating loaded samples."
		print "User must check these values before proceeding!" 
		IF (test==0)
			print "No new Explist wave was create -> check if entries are correct"
		ELSE
			print "New Explist wave was created automatically"
		ENDIF
		IF(numpnts(ExpList)==1)
			print "NOTE: only 1 sample found in loaded data!"
		ENDIF
	ENDIF
ENDIF

// warn user if AMS itx was loaded
IF (MStype>=4 && loadFileType==1)
	String AMSAlert="AMS/ACSM data was loaded from one .itx file\r\r"
	AMSAlert+="User must manually change the wavenames in MaS-PET panel.\rCheck history window for loaded wavenames"
	DoAlert 0,AMSAlert
ENDIF

END

//======================================================================================
//======================================================================================
// set default file extension for data loader files

FUNCTION MPprep_DL_defaultExtensionSet(ctrlStruct)

STRUCT WMSetVariableAction &ctrlStruct

IF (ctrlStruct.eventCode==8)	//8: end edit
	Wave/T FileExtensions=root:APP:dataloader:FileExtensions
	// set all file extensions to this value
	FileExtensions=ctrlStruct.sval
	
	FileExtensions[8]="itx"	//AMS/ACSM exeption
ENDIF

END

//======================================================================================
//======================================================================================

//========================================
//		Error calc panel procedures
//========================================

//======================================================================================
//======================================================================================

// Purpose:		create PL error panel to have the user chose the PL error function
//					Names of all related procdures start with "MPprep_PLE"
//
// Input:			SGfolderName:	string name of folder with results from DoSGerror()
//					wavenames:		txt wave with name of waves (msdata,mserr,exactMZ,ionlabel,Tdesorp)
// 					UseOldParams		optional! draw panel with existing parameters
//
// Output:		PLerror_Panel with:
//						fitted Sij vs class signal plot
//						table with copy of values from Sij fitting (makes copy to prevent loosing data)
//						
// called by:	MPprep_DoSGerror() or from MaS-PET panel button


FUNCTION MPprep_PLE_PLErr_Panel_main(SGfolderName,Wavenames[,UseOldParams])

String SGfolderName	// string with name of SG folder (root:APP:SG_err)
Wave/T wavenames		// names of data waves
Variable UseOldParams	// 1: use existing parameters

IF (paramisdefault(UseOldParams))
	UseOldParams=0
ENDIF

// set Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution=?"
Variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

// get waves (originals)
Wave Sij_SG_all= $(SGfolderName+":Sij_SG_all")	// fitted errors
Wave Sij95_SG_all= $(SGfolderName+":Sij95_SG_all")	// 95% confidence
Wave points_all= $(SGfolderName+":points_all")		// number of points per class
Wave mass_SG_all= $(SGfolderName+":mass_SG_all")		// signal intensity of each class

// make duplicate of waves (to protect original!)
Newdatafolder/O/S root:APP:PLerror
String BaseName="root:APP:PLerror:"

IF (Useoldparams==0)
	Make/D/O/N=(numpnts(points_all)) $(BaseName+"Sij_SG_all")	// use more complicated way to avoid duplicte wave names
	Make/D/O/N=(numpnts(points_all)) $(BaseName+"points_all")
	Make/D/O/N=(numpnts(points_all)) $(BaseName+"Sij95_SG_all")
	Make/D/O/N=(numpnts(points_all)) $(BaseName+"mass_SG_all")
	
	Wave Sij=$(BaseName+"Sij_SG_all")		// fitted errors
	Sij=Sij_SG_all
	Wave Sij95=$(BaseName+"Sij95_SG_all")	// 95% confidence
	Sij95=Sij95_SG_all
	Wave points=$(BaseName+"points_all")	// number of points per class
	points=points_all
	Wave mass=$(BaseName+"mass_SG_all")	// signal intensity of each class
	mass=mass_SG_all
ELSE
	// use existing waves
	Wave Sij=$(BaseName+"Sij_SG_all") 
	Wave Sij95=$(BaseName+"Sij95_SG_all")
	Wave points=$(BaseName+"points_all")
	Wave mass=$(BaseName+"mass_SG_all")
ENDIF

// get minimum error as median of s_noise
NVAR CNtype=root:APP:CNtype_VAR

Wave s_noise=$(SGfolderName+":s_noise")
Wavestats/PCST s_noise
Wave M_wavestats

Variable MinErr
SWITCH (CNtype)
	// end
	CASE 0:
		MinErr=M_wavestats[10][3]	// last 20 data points, signal <2
		BREAK
	// all
	CASE 1:
		MinErr=M_wavestats[10][1]	// last 20 data points, signal <2
		BREAK
	// less then median
	CASE 2:
		MinErr=M_wavestats[10][5]	// last 20 data points, signal <2
		BREAK
ENDSWITCH
Killwaves/Z M_wavestats

// storage for fit
IF (Useoldparams==1)
	Make/O/D/N=(200) PLfit_x,PLfit_y		// for drawing fit
	PLfit_x=10^(log(wavemax(mass))/200*p)-1	// make log spaced x values for fit
	PLfit_x[0]=1e-2	// set to non 0 for log scale
	
	make/O/D/N=(3) PLfit_coef,PLfit_sigma	// fit parameters and sigma
	
	Note PLfit_coef, "y0:y offset;A:amplitude factor;pow:power parameter"
ELSE
	// use previous ones
	Wave PLfit_x=root:app:PLError:PLfit_x
	Wave PLfit_y=root:app:PLError:PLfit_y
	Wave PLfit_coef=root:app:PLError:PLfit_coef
	Wave PLfit_sigma=root:app:PLError:PLfit_sigma
ENDIF

// make panel with graph and table
Killwindow/Z $("PLerror_Panel")

NewPanel /K=1/W=(1300,50,1800,700)/N=PLerror_Panel as "PL error Panel"
ShowInfo/W=PLerror_Panel

// graph
Display/W=(10,55,550,400)/HOST=PLerror_Panel  Sij vs mass	// tracename: Sij_SG_all
RenameWindow #,Sij_plot

ErrorBars Sij_SG_all Y,wave=(Sij95,Sij95)

ModifyGraph mode=2,lsize=3,log=1
ModifyGraph tick=2,mirror=1,fStyle=1,fSize=16,axThick=2,standoff=0

// colour code with number of points in class
ModifyGraph zColor(Sij_SG_all)={points_all,*,*,Rainbow,1},logZColor=1

// set up axis
SetAxis bottom *,*
SetAxis left *,*

LAbel left, "fitted Sij"
Label bottom,"signal strength"

// draw minimum error
SetDrawLayer Userback
SetDrawEnv ycoord= left,dash= 3,linethick= 2.50
DrawLine 0,minErr,1,minErr
SetDrawEnv ycoord= left
DrawText 0.75,minErr*1.1,"minimum Error"
SetDrawLayer UserFront

// colour bar
ColorScale/C/N=text0/X=-35.00/Y=12.00/B=1 "\\f01\\Z14points per class"
ColorScale/C/N=text0/F=0/A=MC trace=Sij_SG_all,log=1,lblMargin=10,fsize=14,fstyle=1

//Table
Edit/W=(10,430,550,640)/HOST=PLerror_Panel  mass,points,Sij,Sij95
RenameWindow #,Sij_table
ModifyTable format(Point)=1

// Functionality
//checkboxes
checkbox cb_useStdev, pos={10,10}, title="use stdev as weight",value=1,fsize=13,frame=0,font="Arial"
checkbox cb_useSqrt, pos={150,10}, title="use square root",value=0,fsize=13,frame=0,font="Arial"
checkbox cb_useMinerror, pos={270,10}, title="use min Error",value=0,fsize=13,frame=0,font="Arial"

//button
Button but_doPLfit pos={400,10},title="fit",size={40,20},font="Arial",fstyle= 1,fsize=13,proc=MPbut_PLerrPanel_button_control
Button but_doPLfitcalc pos={325,35},title="calc",size={40,20},font="Arial",fstyle= 1,fsize=13,proc=MPbut_PLerrPanel_button_control

Button but_doPLerr pos={400,35},title="do PLerror",size={95,20},font="Arial",fstyle= 1,fsize=13,proc=MPbut_PLerrPanel_button_control

Button but_ResetData pos={400,405},title="Reset Data",size={95,20},font="Arial",fstyle= 1,fsize=13,proc=MPbut_PLerrPanel_button_control

//parameters
SetVariable VarNum_fit_A pos={100,35},title=" ",value=PLfit_coef[1],limits={-inf,inf,0},size={45,18},font="Arial",fstyle= 0,fsize=13
SetVariable VarNum_fit_power pos={220,35},title=" ",value=PLfit_coef[2],limits={-inf,inf,0},size={45,18},font="Arial",fstyle= 0,fsize=13
SetVariable VarNum_fit_y0 pos={275,35},title=" ",value=PLfit_coef[0],limits={-inf,inf,0},size={45,18},font="Arial",fstyle= 0,fsize=13

TitleBox Title_PLerror1,pos={10,35},title="MSerr_PL = ",fstyle= 1,fsize= 14,frame=0,font="Arial"
TitleBox Title_PLerror2,pos={145,35},title="* MSdata ^",fstyle= 1,fsize= 14,frame=0,font="Arial"
TitleBox Title_PLerror3,pos={266,35},title="+",fstyle= 1,fsize= 14,frame=0,font="Arial"

// checkbox for log axis
checkbox cb_log, pos={10,400}, title="log axis",value=1,fsize=13,frame=0,font="Arial", proc=MPbut_cb_log_func

// help button
Button but_help_PLerrPanel,pos={450,10},size={17,17},title="?",fstyle=1,fsize=12,fColor=(65535,32768,58981),proc=MPbut_help_button_control

// reset Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

END

//======================================================================================
//======================================================================================

// Purpose:		fit data in PLerror Panel as set by checkboxes
//					using power law

// Input:			ctrlName:	txt wave with names of experiment folders
//					Fit constrains from checkboxes in PLerror panel
// 				
// Output:		PLfit_coef:			fit parameter
//					PLfit_sigma:			error of fit
//					PLfit_y/PLfit_x:		values to draw fitted curve in graph
// called by:	MPprep_PLE_PLErr_Panel_main()


FUNCTION MPprep_PLE_DoPLFit()

// get basic waves

String BaseName="root:APP:PLerror:"

Wave Sij=$(BaseName+"Sij_SG_all")		// fitted errors
Wave Sij95=$(BaseName+"Sij95_SG_all")	// 95% confidence
Wave points=$(BaseName+"points_all")	// number of points per class
Wave mass=$(BaseName+"mass_SG_all")	// signal intensity of each class

Wave PLfit_x=$(BaseName+"PLfit_x")
Wave PLfit_y=$(BaseName+"PLfit_y")
Wave PLfit_coef=$(BaseName+"PLfit_coef")
Wave PLfit_sigma=$(BaseName+"PLfit_sigma")

Wave s_noise=root:APP:SG_err:s_noise		// sigma noise values

NVAR CNtype=root:app:CNtype_VAR	// whihc type of CN stdev calc to use

// get minimum error as median of s_noise
Wavestats/PCST s_noise
Wave M_wavestats

Variable MinErr
SWITCH (CNtype)
	// end
	CASE 0:
		MinErr=M_wavestats[10][3]	// last 20 data points, signal <2
		BREAK
	// all
	CASE 1:
		MinErr=M_wavestats[10][1]	// last 20 data points, signal <2
		BREAK
	// less then median
	CASE 2:
		MinErr=M_wavestats[10][5]	// last 20 data points, signal <2
		BREAK
ENDSWITCH
Killwaves/Z M_wavestats

// get info from Panel (checkbox setting not saved elsewhere)
// use stdev for fit?
Controlinfo/W=PLerror_Panel cb_useStdev
Variable useStdev_checked=V_value	// 1: checked

// use fixed parameter for power (sqrt -> 0.5)
Controlinfo/W=PLerror_Panel cb_useSqrt
Variable useSqrt_checked=V_value

// use minimum error for distance(+C = minimu m error from SQ error calc)
Controlinfo/W=PLerror_Panel cb_useminError
Variable useMinErr_checked=V_value

// prepare fit constrains
String holdStr=""

// minimum error selected
IF (useMinErr_checked)
	holdStr="10"
	// get minimum error value
	PLfit_coef[0]=minErr	// use median of res(data) for last 20 datapoints with signal<2
	PLfit_sigma[0]=0
ELSE
	holdStr="00"
ENDIF

// hold power parameter
IF(useSqrt_checked)
	holdStr+="1"
	
	PLfit_coef[2]=0.5
	PLfit_sigma[2]=0
ELSE
	holdStr+="0"
	
ENDIF

// use standard deviation for weighing
IF (!useStdev_checked)
	// set wave ref to NULL to turn off stdev weighing
	Wave Sij95=$""
	
ENDIF

// do the fit
Debuggeroptions
Variable debugOnError_setting=V_debugOnError

TRY
	DebuggerOptions debugOnError=0	// turn off debug window

	CurveFit/Q/N/H=holdStr Power kwCWave=PLfit_coef Sij /X=mass /W=Sij95 /I=1 /NWOK ;AbortOnRTE

	DebuggerOptions debugOnError=debugOnError_setting	// set debugger to previous value

	// update calculated fit
	PLfit_y= PLfit_coef[0]+PLfit_coef[1]*PLfit_x[p]^PLfit_coef[2]

	// draw fit if needed
	String traces=tracenameList("PLerror_panel#Sij_plot",";",1)

	IF(whichlistitem("PLfit_y",traces)<0)
		appendtograph/W=PLerror_Panel#Sij_plot PLfit_y vs PLfit_x
		ModifyGraph/W=PLerror_Panel#Sij_plot lsize(PLfit_y)=2,rgb(PLfit_y)=(0,0,0)
	ENDIF

CATCH
	DebuggerOptions debugOnError=debugOnError_setting	// set debugger to previous value
	print "DoPLFit:\tunable to create fit"
ENDTRY


END

//======================================================================================

// Purpose: 		calculate fitted curve with current parameters
// Input:			fit parameters from PL error panel
// Output:		line in PL panel graph with current fit parameters	
// called by:	Button in PLerror Panel	

FUNCTION MPprep_PLE_DoPLfitCalc()

// get basic waves

String BaseName="root:APP:PLerror:"

Wave PLfit_x=$(BaseName+"PLfit_x")
Wave PLfit_y=$(BaseName+"PLfit_y")
Wave PLfit_coef=$(BaseName+"PLfit_coef")
Wave PLfit_sigma=$(BaseName+"PLfit_sigma")

PLfit_y= PLfit_coef[0]+PLfit_coef[1]*PLfit_x[p]^PLfit_coef[2]

// draw fit if needed
String traces=tracenameList("PLerror_panel#Sij_plot",";",1)

IF(whichlistitem("PLfit_y",traces)<0)
	appendtograph/W=PLerror_Panel#Sij_plot PLfit_y vs PLfit_x
	ModifyGraph/W=PLerror_Panel#Sij_plot lsize(PLfit_y)=2,rgb(PLfit_y)=(0,0,0)
ENDIF


END

//======================================================================================

// Purpose: 		calculate PL error for all samples listed in selected expList wave
// Input:			explist from FiT-PET panel
//					wavenames from FiT-PET Panel

// Output:		MSerr_PL:	PL error for all sample folders using name from FiT-PET panel and adding _PL	
// called by: 	Button in PLError Panel		

FUNCTION MPprep_PLE_DoPLerr()

// get parameter waves
Wave PLfit_coef=root:App:PLerror:PLfit_coef
Wave s_noise=root:APP:SG_err:s_noise

SVAR abortStr=root:APP:abortStr

NVAR CNtype=root:app:CNTYPE_VAR

// catch missing wave
IF (!Waveexists(PLfit_coef))
	abortStr="MPbut_DoPLerr() - do PLerror button:\r\rPLfit_coef wave does not exist. Make sure to first fit the PL error at least once."
	MPaux_abort(AbortStr)
ENDIF

IF (!Waveexists(s_noise))
	abortStr="MPbut_DoPLerr() - do PLerror button:\r\rs_noise wave does not exist. Make sure to run MSerr calculation at least once."
	MPaux_abort(AbortStr)
ENDIF

// get waves with info about experiment
SVAR ExpList_Str=root:APP:expList_Str
Wave/T Explist=$ExpList_Str
Wave/T DataWavenames=root:App:dataWavenames

// catch missing wave
IF (!Waveexists(ExpList))
	abortStr="MPbut_DoPLerr() - do PLerror button:\r\rmissing wave:\r"+ExpList_Str
	abortStr+="\r\rcheck name of Explist wave"
	MPaux_abort(AbortStr)
ENDIF

// check name of error wave
String Errorname=DataWavenames[1]

Errorname=removeending(Errorname,"_CN")	// fix MSerr_CN
Errorname=removeending(Errorname,"_PL")	// fix MSerr_PL	

ErrorName+="_PL"	// add ID tag

// get minimum error
Wavestats/PCST s_noise
Wave M_wavestats

Variable MinErr
SWITCH (CNtype)
	// end
	CASE 0:
		MinErr=M_wavestats[10][3]	// last 20 data points, signal <2
		BREAK
	// all
	CASE 1:
		MinErr=M_wavestats[10][1]	// last 20 data points, signal <2
		BREAK
	// less then median
	CASE 2:
		MinErr=M_wavestats[10][5]	// last 20 data points, signal <2
		BREAK
ENDSWITCH


// loop through folder list
Variable ff
String FolderName
String NoteStr=""
Variable test=0
	
FOR (ff=0;ff<numpnts(expList);ff+=1)
	
	FolderName="root:"+ExpList[ff]
	FolderName=replaceString("root:root:",FolderName,"root:")

	// get data wave
	Wave msdata=$(FolderName+":"+DataWaveNames[0])
	
	IF (Waveexists(msdata))	// catch if wave exists
		test+=1
		Make/D/O/N=(dimsize(msdata,0),dimsize(msdata,1)) $(folderName+":"+ErrorName)

		Wave MSerr=$(folderName+":"+ErrorName)
		
		// calculate error values
		Mserr= PLfit_coef[0]+PLfit_coef[1]*MSdata[p][q]^PLfit_coef[2]
	
		// set minimum error
		MSerr = MSerr [p][q] < minErr ? minErr : MSerr[p][q]
		
		// set note
		NoteStr="Mserr_PL= "+num2str(PLfit_coef[0])+"+"+num2Str(PLfit_coef[1])+"*MSdata[p][q]^"+num2str(PLfit_coef[2])
		NoteStr+="\rMSerr_PL = MSerr_PL [p][q] < "+num2str(minErr)+" ? "+num2str(minErr)+" : MSerr_PL[p][q]"
		Note Mserr,Notestr
		
	ELSE
		print "no wave found with Name: "+DataWaveNames[0]+" in folder "+FolderName
			
	ENDIF

	Wave MSdata=$""
	
ENDFOR	// folder loop

IF (test>0)
	print "--------------------------"
	print date() +" "+time()+ " PLerror matrix calculated for all folders in: "+Explist_STr
	print " + to use these values, user must change wave name in panel to: "+ErrorName

ENDIF

END

//======================================================================================
//======================================================================================

// Purpose: 		reset the fitted Sij values in the PLerror Panel back to original values
// Input:			explist from FiT-PET panel
//					wavenames from FiT-PET Panel

// Output:		MSerr_PL:	PL error for all sample folders using name from FiT-PET panel and adding _PL	
// called by: 	Button in PLError Panel		

FUNCTION MPprep_PLE_ResetData()

// get waves
// original
SVAR SGerrorFolderName=root:APP:SGerrorFolderName	// name of folder with SG error data for PL error parameter fit
SGerrorFolderName=removeending(SGerrorFolderName,":")

Wave Sij_SG_all= $(SGerrorFolderName+":Sij_SG_all")	// fitted errors
Wave Sij95_SG_all= $(SGerrorFolderName+":Sij95_SG_all")	// 95% confidence
Wave points_all= $(SGerrorFolderName+":points_all")		// number of points per class
Wave mass_SG_all= $(SGerrorFolderName+":mass_SG_all")		// signal intensity of each class

// Waves in Panel
String BaseName="root:APP:PLerror:"

Wave Sij=$(BaseName+"Sij_SG_all")		// fitted errors
Wave Sij95=$(BaseName+"Sij95_SG_all")	// 95% confidence
Wave points=$(BaseName+"points_all")	// number of points per class
Wave mass=$(BaseName+"mass_SG_all")	// signal intensity of each class

// reset values
Sij=Sij_SG_all[p]
Sij95=Sij95_SG_all[p]
points=points_all[p]
mass=mass_SG_all[p]

END

//======================================================================================
//======================================================================================

