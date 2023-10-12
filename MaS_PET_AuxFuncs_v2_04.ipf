#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include <WaveselectorWidget>	// needed for thermogram plotter

//======================================================================================
//	MaS_PET_AuxFuncs is a collection of auxilliary functions for MaS-PET. 
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

//========================================
//========================================
//			APP auxilliary functions
//========================================
//========================================

//========================================
//		general aux  procedures
//========================================

//======================================================================================
//======================================================================================


// Purpose:	converts igor julian seconds to string

// Input:		seconds: 	seconds value that should be converted to a data-time string
//				format:	string defining the output format of the data-time string.
//							supported formats:
//								"dd.mm.yyyy hh:mm:ss"
//								"hh:mm:ss dd.mm.yyyy"
//								"yyyy-mm-dd hh:mm:ss"
//								"dd.mm.yyyy"
//								"dd/mm/yyyy"
//								"yyyy-mm-dd"
//								"hh:mm:ss"
// Output:	string with date+time in specified format


Function/S MPaux_js2String(seconds,format[,noAbort])		//format is the format of the return string
String format
Variable Seconds
Variable noABort

IF (PAramisDefault(nOAbort))
	noAbort=0
ENDIF

String timeString
String TempDateStr=secs2Date(seconds,-2)		//yyyy-mm-dd
String TempTimeStr=secs2time(seconds,3)		//hh:mm:ss

IF (NumType(seconds)==0)
	StrSwitch (format)
		CASE "dd.mm.yyyy hh:mm:ss":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			timeString=timeString+" "+tempTimeStr
			BREAK
		CASE "hh:mm:ss dd.mm.yyyy":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			timeString=tempTimeStr+" "+timeString
			BREAK
		CASE "yyyy-mm-dd hh:mm:ss":
			timeString=tempDateStr+" "+ tempTimeStr
			BREAK
		CASE "dd.mm.yyyy":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			BREAK
		CASE "dd/mm/yyyy":
			timestring=StringFromList(2,TempDateStr,"-")+"/"+StringFromList(1,TempDateStr,"-")+"/"+StringFromList(0,TempDateStr,"-")
			BREAK
		CASE "yyyy-mm-dd":
			timeString=TempDateStr
			BREAK
		CASE "hh:mm:ss":
			timeString=tempTimeStr
			BREAK
		DEFAULT:
			IF (noabort==0)
				abort "MSaux_js2string: unknown time format "+format
			ELSE
				// return flag
				timeString="Wrong Format"
			ENDIF
	ENDSwitch
ELSE
	timeString=""		//if NaN or inf was passed: return empty field
ENDIF

RETURN timeString
END

//======================================================================================
//======================================================================================

// Purpose:	converts date-time string to Igor julian seconds

// Input:		timeString: 	strng with dat-time stamps
//				format:		string defining the input format of the timeString
//								supported formats:
//									"dd.mm.yyyy hh:mm:ss"
//									"hh:mm:ss dd.mm.yyyy"
//									"yyyy-mm-dd hh:mm:ss"
//									"dd.mm.yyyy"
//									"dd/mm/yyyy"
//									"yyyy-mm-dd"
//									"hh:mm:ss"
//									"mm/dd/yy hh:mm:ss"	
//									"hh:mm:ss dd/mm/yy"
//									"dd/mm/yyyy hh:mm:ss"
//									"m/d/yyyy hh:mm:ss AM"
//				optional:
//					noABort:	1: do not abort but return -999
	
// Output:	julian seconds in Igor format

Function MPaux_String2js(timeString,format[,noAbort])	//format is the format of the input string

string timeString, format

Variable noABort

IF (PAramisDefault(nOAbort))
	noAbort=0
ENDIF
//------------------------
Variable Seconds
String TempTimeStr,TempDateStr

String abortStr=""

String AMPM=""	// AMPM="" no AM indicator "PM" has indicator

IF (stringmatch("",timeString)!=1)
	StrSwitch (format)
		CASE "hh:mm:ss dd.mm.yyyy":
			IF (ItemsInList(TimeString," ")!=2)
				abortStr= "ERROR MPaux_String2js: given format does not match input data (1)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(0,TimeString," ")
			TempDateStr=StringFromList(1,TimeString," ")
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (2)"
			ENDIF
			BREAK
		CASE "dd.mm.yyyy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (3)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (4)"
			ENDIF
			BREAK
		CASE "yyyy-mm-dd hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (5)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"-")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (6)"
				BREAK
			ENDIF
			tempDateStr=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")	//put date into "standard" format: dd.mm.yyyy
			BREAK
		CASE "mm/dd/yy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (7)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (8)"
				BREAK
			ENDIF
			TempDateStr=StringFromList(1,TempDateStr,"/")+"."+StringFromList(0,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "hh:mm:ss dd/mm/yy":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (9)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(0,TimeString," ")
			TempDateStr=StringFromList(1,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (10)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "dd.mm.yyyy":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (11)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (12)"
				BREAK
			ENDIF

			BREAK
		CASE "yyyy-mm-dd":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (13)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			tempDateStr=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")	//put date into "standard" format: dd.mm.yyyy
			BREAK
		CASE "dd/mm/yyyy":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (14)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			IF (strlen(StringFromList(2,TempDateStr,"/"))==4)
				TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			ELSE	//catch 2 digit year
				TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			ENDIF
			
			BREAK
		CASE "hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abort "ERROR MPaux_String2js: given format does not match input data (15)"
				BREAK
			ENDIF

			TempTimeStr=TimeString
			TempDateStr="01.01.1904"	//zero in igor Date
			BREAK
		CASE "dd/mm/yyyy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (16)"
				BREAK
			ENDIF

			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (17)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "m/d/yyyy hh:mm:ss AM":
			IF (ItemsInList(TimeString," ")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (18)"
				BREAK
			ENDIF

			TempTimeStr=StringFromList(1,TimeString," ")
			AMPM=StringFromList(2,TimeString," ")	// catch AM PM shit
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (19)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(1,TempDateStr,"/")+"."+StringFromList(0,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			BREAK
		DEFAULT:
			abortStr= "ERROR MPaux_String2js: unknown time format "+format+"(20)"
	ENDSWITCH
	
	// check if problem occured and return -999
	IF (!StringMatch(abortSTr,""))
		IF (noAbort==1)
			seconds=-999
			print abortSTr
			Return seconds
		ELSE
			Abort abortSTr
		ENDIF

	ENDIF
		
	//check some common mistakes
	IF (ItemsInList(TempTimeStr,":")==2)
		TempTimeStr+=":00"	//add missing seconds
	ELSEIF (ItemsInList(TempTimeStr,":")!=3)
		abortStr= "ERROR MPaux_String2js: time part must be of format: ...hh:mm:ss..."
	ENDIF
	IF (strLen(StringFromList(2,TempDateStr,"."))==2)
		TempDateStr=StringFromList(0,tempDateStr,".")+"."+StringFromList(1,tempDateStr,".")+".20"+StringFromList(2,tempDateStr,".")	//convert two digit year to four digits (only works after 2000!!!!)
	ELSEIF(strLen(StringFromList(2,TempDateStr,"."))!=4)
		abortStr= "ERROR MPaux_String2js: use 4 digit year: make sure that date matches given format"
	ENDIF
	
	IF (StringMatch(abortSTr,""))
		
		Seconds=date2secs(str2num(StringFromList(2,TempDateSTr,".")),str2num(StringFromList(1,TempDateStr,".")),str2num(StringFromList(0,TempDateStr,".")))
		Seconds+=str2num(StringFromList(0,tempTimeStr,":"))*3600+str2num(StringFromList(1,tempTimeStr,":"))*60+str2num(StringFromList(2,tempTimeStr,":"))
		
		// catch AM/PM
		IF (stringmatch(AMPM,"PM") && stringmatch(StringFromList(0,tempTimeStr,":"),"12"))
			seconds+=12*3600	// add 12h
		ENDIF
	ELSE
		IF (noAbort==1)
			seconds=-999
			print abortSTr
		ELSE
			Abort abortSTr
		ENDIF
	ENDIF
ELSE
	seconds=NaN	//if empty field was passed: put in NaN
ENDIF
		
RETURN Seconds
END

//======================================================================================
//======================================================================================

// Purpose:	convert Matlab time values to Igor seconds
// Input:		MatLabSec	: matlab time values
// 				
// Output :	time in Igor seconds


Function MPaux_Matlab2IgorTime(MatLabSec)

Variable MatLabSec	 //Matlab in days since 0.Jan 0000

Variable offset=695422	// 1.1.1904 in Matlab time
Variable IgorSec=(MatlabSec-offset)*60*60*24

RETURN IgorSec

END

//======================================================================================
//======================================================================================

// Purpose:	convert Igor time values to MAtlab seconds
// Input:		IgorSec	: matlab time values
// 				
// Output :	time in MatLab seconds


Function MPaux_Igor2MatlabTime(IgorSec)

Variable IgorSec	 

Variable offset=695422	// 1.1.1904 in Matlab time
Variable MatLabSec=IgorSec/60/60/24 + offset

RETURN MatLabSec	//Matlab in days since 0.Jan 0000

END


//======================================================================================
//======================================================================================

// Purpose:	asymetric log log function for fitting of SMPS/DMPS data
//				if result is NaN output wave is set to 0
// Input:		parameter wave, Dp
// Output:	f(Dp)


Function MPaux_asymLogLogNaN(pw,yw,xw) : FitFunc
	Wave pw,xw,yw
	
	//Equation:
	// f(Dp) = p0*exp(-ln(2)*(ln(1+(Dp-p1)*(p3^2-1)/p2/p3)^2)/(ln(p3))^2)
	// Dependent Variable: Dp
	// Coefficients: 4
	// pw[0] = p0
	// pw[1] = p1
	// pw[2] = p2
	// pw[3] = p3
	
	yw = (1+(xw-pw[1])*(pw[3]^2-1)/pw[2]/pw[3])>0 ? pw[0]*exp(-ln(2)*(ln((1+(xw-pw[1])*(pw[3]^2-1)/pw[2]/pw[3]))^2)/(ln(pw[3]))^2) : 0
	
End

//======================================================================================
//======================================================================================

// Purpose:	create multiple subfolders in one go
//				folder is created from current position

// Input:		NewFolderName:	full path for new folder 													
//				Set:				0: go back to current foledr, 1: set new folder
// Output:	folder tree down to NewFolderName


FUNCTION MPaux_NewSubfolder(NewFolderName,set )

String NewFolderName
Variable Set

Variable nof=Itemsinlist(NewfolderName,":")
Variable ff

String OldFolder=getDataFolder(1)

FOR (ff=0;ff<nof;ff+=1) 
	String currentLevel=StringfromList(ff,NewFolderName,":")
	// first entry is root
	IF (stringmatch(currentlevel,"root"))
		setdatafolder root:
	ELSE
		// set to existing
		IF (datafolderexists(currentlevel) )
			setdatafolder $CurrentLevel
		ELSE
		// or make new one	
			Newdatafolder/S $Currentlevel
		ENDIF
	ENDIF
	
ENDFOR

// set back to old folder
IF (set==0)
	SetdataFolder $OldFolder
ELSE
	Setdatafolder $NewFOlderName
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	like normal abort but check abortStr for length first
//				IF abortStr is too long -> print to history window instead
//				
// Input:		abortStr:	String with message for abort
//				
// Output:	either abort popup with message OR simple abort message and print to history

FUNCTION MPaux_abort(abortStr)

String abortStr

String alertStr=""

// maximum length of string for abort popup
Variable MaxLength=254	// max length for Igor 7
IF (Igorversion()>=8.00)
	MaxLength=1023	// max length for Igor 8
ENDIF

//check abort String length
IF (Strlen(abortStr)>maxLength)
	// too long -> print to history
	
	// create simple alertStr: using \r\r to identify calling procedure
	alertStr=StringfromList(0,abortSTr,"\r\r")
	alertStr+="\r\r!Problem detected - aborting! Check History window for details."

	// print to history
	abortStr=replacestring("\r\r",abortStr,"\r")	// remove empty lines
	print "-----------------"
	print abortStr
	print "-----------------"
	
ELSE
	alertStr=abortStr
ENDIF

// display dialog with OK button
DoAlert 0,alertStr

// and abort
Abort

END

//======================================================================================
//======================================================================================

// Purpose:	check which MaS-PET related panel exist and redraw them with proper resolution
//
// Input:		
//
// Output:	redrawn panels (containing the same parameters as before)

FUNCTION MPaux_fixPanelResolution()

// get old resolution setting and set standard
Execute/Q/Z "SetIgorOption PanelResolution=?"
variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

//----------------------
// Handle main MaSPET panel

// check if Panel exists
IF (!Wintype("MaSPET_Panel"))
	// no panel -> create new one
	MPmain_showMAS_PET_PANEL()
ELSE
	MPmain_MaS_PET_main(UseOldparams=1)
ENDIF

// update MStype radio buttons
// determine MStype
Wave radioValues_MSType=root:APP:radioValues_MSType

String CtrlName
String CtrlList
Variable ii

// check main type (-> create subwave for settings loop)
IF (radioValues_MSType[%Gas_MS]==1)
	Make/FREE/D/N=(3) RadioSettings
	RadioSettings=radioValues_MSType[p]
	
	Ctrllist=Getdimlabel(radioValues_MSType,0,0)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,1)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,2)+";"
ENDIF

IF (radioValues_MSType[%FIGAERO]==1)
	Make/FREE/D/N=(3) RadioSettings
	RadioSettings=radioValues_MSType[p+3]
	
	Ctrllist=Getdimlabel(radioValues_MSType,0,3)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,4)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,5)+";"
ENDIF

IF (radioValues_MSType[%aero_MS]==1)
	Make/FREE/D/N=(3) RadioSettings
	RadioSettings=radioValues_MSType[p+6]
	
	Ctrllist=Getdimlabel(radioValues_MSType,0,6)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,7)+";"
	Ctrllist+=Getdimlabel(radioValues_MSType,0,8)+";"
ENDIF

// set depending things
FOR(ii=0;ii<numpnts(RadioSettings);ii+=1)
	IF (RadioSettings[ii]==1)
		Ctrlname="radio_MSType_"+Stringfromlist(ii,CtrlList)
		MPbut_radio_MSType_action(Ctrlname)	
	ENDIF

ENDFOR

//----------------------
// Dataloader Panel
DoWIndow/F DataLoader_panel

IF (V_flag)
	// window exists -> recreate (automatically uses existing values)
	MPprep_DL_DataLoader_Panel()
ENDIF

//----------------------
// PLerror panel
// variables
Wave/T Wavenames=root:APP:DataWavenames
SVAR SGerrorFolderName=root:APP:SGerrorFolderName
SGerrorFolderName=removeending(SGerrorFolderName,":")
	
IF (Wintype("PLerror_Panel"))
	// variables for recreation
	// check if original has fit line
	String traces=tracenameList("PLerror_panel#Sij_plot",";",1)
	
	// redraw 
	MPprep_PLE_PLErr_Panel_main(SGerrorFolderName,Wavenames)
			
	// add fit line
	IF(whichlistitem("PLfit_y",traces)>=0)
		Wave PLfit_y=root:APP:PLerror:PLfit_y
		Wave PLfit_x=root:APP:PLerror:PLfit_x

		appendtograph/W=PLerror_Panel#Sij_plot PLfit_y vs PLfit_x
		ModifyGraph/W=PLerror_Panel#Sij_plot lsize(PLfit_y)=2,rgb(PLfit_y)=(0,0,0)
	ENDIF

ENDIF

//----------------------
// FactorIonTS
IF (WIntype("FactorIonTS"))
	//redraw without calculations
	MPaux_FIT_FactorIonTS_Panel()
ENDIF

//----------------------
// PET results
IF(Wintype("pmf_plot_panel"))
	// only redraw panel (assuming everything ewlse is right)
	Killwindow/Z pmf_plot_panel
	
	Execute/Q/Z "SetIgorOption PanelResolution=72"	// to make sure nothing has reset it

	PMF_make_Plot_Panel()

ENDIF

//----------------------
// PET data prep panel

SVAR combiName_str=root:APP:combiName_str

IF(wintype("PMF_PerformCalc_Panel"))
	Killwindow/Z PMF_PerformCalc_Panel
	
	Execute/Q/Z "SetIgorOption PanelResolution=72"	// to make sure nothing has reset it
	pmfCalcs_makePanel()
	
	//MaS-PET extra things
	MPprep_TransferWavenames2PET(combiName_str,Wavenames)
					
	// set tab to prep or run
	NVAR MStype_VAR=root:APP:MStype_VAR
	IF (MStype_VAR==7)
		// for old ACSM
		pmfCalcs_tabRedraw("tab_PrepExecAdv", 1)
		tabControl tab_PrepExecAdv value=1  // set tab to Run
	ELSE
		pmfCalcs_tabRedraw("tab_PrepExecAdv", 0)
		tabControl tab_PrepExecAdv value=0  // set tab to prep
	ENDIF
	
	// set hook for PET window
	Setwindow PMF_PerformCalc_Panel,hook(PETprep_hook)=MPaux_PETprep_hook

ENDIF

// reset old value
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

END

//======================================================================================
//======================================================================================

// Purpose:	Prompt user for wavenames to use in MPaux_makeWaves4PMF
//				first guess is panel names
//
// Input:		folderPath:	Full path to folder where Waves4PMF should be created
//				Wavenames:	Text wave with names of data waves as they are in main panel
//				CtrlName:		Name of button that called the parent function
//				Check:			1: perform a check if waves exist in current folder (do not do that for solution folder 
//
// Output:	Wavenames_temp in current folder

FUNCTION MPaux_Prompt4Wavesnames(folderPath,Wavenames,ctrlName,check)

String folderPath
Wave/T wavenames
String CtrlName
Variable check

// get additional variable
NVAR MStype_VAR=root:app:MStype_VAR
SVAR AbortSTR=root:app:abortStr

Variable ii

String labelDummy=""
String Waves4PMF_list=""

// prompt user for wavenames	// idxSample is handled in MPaux_MakeWaves4PMF()
String MSdataName=Wavenames[%MSdataName]
String MSerrName=Wavenames[%MSerrName]
String MZName=Wavenames[%MZName]
String LabelName=Wavenames[%LabelName]
String Tname=Wavenames[%Tname]

String FigTimeName=Wavenames[%FigTimeName]
IF (MStype_VAR!=2)
	FigTimeName=""
ENDIF	

String NameList="MSdataName;MSerrName;MZName;LabelName;Tname;FigTimeName;"	

Prompt MSdataName,"MS data"
Prompt MSerrName,"Error Matrix"
Prompt Tname,"time series or desorption Temperature"
Prompt MZname,"MZ values(NUM)"
Prompt Labelname,"ion names(TXT)"
Prompt FigTimeName,"time series - FIGAERO thermogram only"

DoPrompt "Select Wave names", MSdataName,MSerrName,MZName,LabelName,Tname,FigTimeName

IF (V_flag==1)
	// user canceled
	Abort

ELSE
	
	// store selected names
	MAKE/O/T/N=(itemsinlist(nameList)) $(FolderPath+":Wavenames_temp")
	Wave/T WAvenames_temp=$(FolderPath+":Wavenames_temp")
	WAvenames_temp=""	
	
	// set dimension labels
	FOR (ii=0;ii<itemsinlist(namelist);ii+=1)
		labelDummy=Stringfromlist(ii,namelist)
		SetDimlabel 0,ii,$labeldummy,Wavenames_temp
	ENDFOR

// set values
	Wavenames_temp[%MSdataName]=MSdataName
	Wavenames_temp[%MSerrName]=MSerrName
	Wavenames_temp[%Tname]=Tname
	Wavenames_temp[%MZname]=MZname
	Wavenames_temp[%Labelname]=Labelname
	
	IF (MStype_VAR==2)	// set Fig Time only for FIGAERO TD data
		Wavenames_temp[5]=FigTimeName
	ELSE
		Wavenames_temp[5]=""
	ENDIF

	// prepare list for checking waves
	FOR (ii=0;ii<itemsinlist(namelist);ii+=1)
		labelDummy=Stringfromlist(ii,namelist)
		
		IF (MStype_VAR!=2)	// everything but FIGAERO TD
			IF (!Stringmatch(labeldummy,"FigTimeName"))
				Waves4PMF_list+=folderPath+":"+Wavenames_temp[ii]+";"
			ENDIF
		ELSE
			// for FIGAERO check if FigTime should be included
			IF (!Stringmatch(labeldummy,"FigTimeName"))
				Waves4PMF_list+=folderPath+":"+Wavenames_temp[ii]+";"	
			ELSE
				// if it is FigTIme -> check if empty
				IF (!stringmatch(Wavenames_temp[%FigTimeName],""))
					Waves4PMF_list+=folderPath+":"+Wavenames_temp[ii]+";"
				ENDIF
			ENDIF
		ENDIF
	ENDFOR


ENDIF

// check if wavenames exist
IF (check==1)
	IF (MPaux_CheckWavesFromList(Waves4PMF_list)==0)
		// at least one wave was missing -> abort
		abortStr="MPbut_step3_button_control: - "+ctrlName+"\r\rProblem with preparing wave4PMF wave:"
		abortStr+="\ruser selected wavenames do not exist in folder:\r\r"+folderPath +"\r"
		
		// add missing waves to abort Str
		Wave/Z NonExistIdx
		Variable ww
		FOR (ww=0;ww<numpnts(NonExistIdx);ww+=1)
			abortStr+="\r"+Stringfromlist(NonexistIdx[ww],Waves4PMF_list)
		ENDFOR
	
		MPaux_Abort(abortStr)
	ENDIF
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	Create Waves4PMF from Names in Wavenames wave in the folderPath location
//				
// Input:		folderPath:	Full path to folder where Waves4PMF should be created
//				Wavenames:	Text wave with names of data waves and
//				
// Output:	Waves4PMF in designated location

FUNCTION MPaux_makeWaves4PMF(folderPath,Wavenames)

String FolderPath
Wave/T Wavenames

FolderPath=removeEnding(FolderPath,":")
				
Make/O/T/N=(Max(7,numpnts(Wavenames)))  $(FolderPath+":Waves4PMF")	
Wave/T/Z Waves4PMF=$(FolderPath+":Waves4PMF")		
Note Waves4PMF, "Names of Waves used for PMF  calcaulations in folder\r"+ FolderPath

// catch if Wavenames wave is too short (for older FiT-PET versions)
IF (numpnts(Wavenames)==5)
	insertPoints 5,2, Wavenames
	Setdimlabel 0, 5, FigTimeName,Wavenames
	Setdimlabel 0, 6, IDXSampleName,Wavenames
	Wavenames[5,6]=""
ENDIF

Waves4PMF[0,5]=Wavenames[p]
Waves4PMF[6]="idxSample"	

// catch nonans waves
IF (stringmatch(Wavenames[0],"nonans_*"))
	Waves4PMF[6]="noNans_idxSample"
ENDIF

// set labels
Variable ii
String LabelDummy
FOR (ii=0;ii<numpnts(Wavenames);ii+=1)
	LAbelDummy=Getdimlabel(Wavenames,0,ii)
	Setdimlabel 0,ii,$LabelDummy, Waves4PMF
ENDFOR

LabelDummy="IdxSampleName"
Setdimlabel 0,6,$LabelDummy, Waves4PMF

END

//======================================================================================
//======================================================================================

// Purpose:	Create PMFSolInfo Wave in the folderPath location
//				contains info about ht esolutions stored in this folder
//				info is pulled from variables in APP folder
// Input:		folderPath:	Full path to folder where Waves4PMF should be created
//				useMStype:	1: use the global MStype_VAR
// Output:	PMFsolInfo in designated location contains: data type, factor number, fpeak or seed, all possible fpeak/seed values

FUNCTION MPaux_makePMFSolinfo(folderPath[,useMStype])

String FolderPath
Variable useMStype

IF (ParamisDefault(useMStype))	// set to 0 if not passed
	useMStype=0
ENDIF


SVAR/Z abortStr=root:app:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

FolderPath=removeEnding(FolderPath,":")

// make wave for information				
Make/O/T/N=(6)  $(FolderPath+":PMFSolinfo")	
Wave/T/Z PMFSolInfo=$(FolderPath+":PMFSolInfo")
PMFSolInfo=""

// annotations		
String NoteStr="fpeak_seed: 0=fpeak,1:seed\rdata type:"
Note/K PMFSolInfo, NoteStr

Setdimlabel 0,0,foldername,PMFSolInfo
Setdimlabel 0,1,factorNum,PMFSolInfo
Setdimlabel 0,2,factor_values,PMFSolInfo
Setdimlabel 0,3,fpeak_seed,PMFSolInfo
Setdimlabel 0,4,fpeak_seed_value,PMFSolInfo
Setdimlabel 0,5,data_type,PMFSolInfo

//get info from actual folder
Wave/Z p_map=$(FolderPath+":p_map")

IF (!waveexists(p_map))
	abortStr="MPaux_makePMFSolInfo:\r\rp_map wave not found in folder\r "+folderPath
	abortStr+="\r\rPMF calcultion must be executed before using this function."
	MPaux_abort(abortStr)
ENDIF

// data folder name
PMFSolInfo[0]=folderPath	

// maximum number of factors (last entry)
PMFSolInfo[1]=num2str(p_map[numpnts(p_map)-1])	

// convert p_map values to string
String list
Make/FREE/T/N=(numpnts(p_map)) p_map_txt
p_map_txt=num2Str(p_map)
wfprintf list, "%s;", p_map_txt
PMFSolInfo[2]=list 	// factor number values

NVAR/Z CalcedSeedOrFpeak=$(FolderPath+":CalcedSeedOrFpeak")	// stored by PET

// fpeak or seed used?
PMFSolInfo[3]=num2str(CalcedSeedOrFpeak)	

// convert fpeak_map values to string
Wave fpeak_map=$(FolderPath+":fpeak_map")
Make/FREE/T/N=(numpnts(fpeak_map)) fpeak_map_txt
fpeak_map_txt=num2Str(fpeak_map)
wfprintf list, "%s;", fpeak_map_txt

// fpeak/seed values
PMFSolInfo[4]=list 	

// get data type  - always ask user
NVAR/Z MStype_VAR=root:app:MStype_VAR
Variable dataTypeNum=1

IF(NVAR_Exists(MStype_VAR))
	dataTypeNum=MStype_VAR
ELSE
	useMStype=0
ENDIF


// prompt user for data type
IF (useMStype==0)
	String HelpStr="Select entry closest to your data type. If nothing fits, use 0 or 1"
	
	String TypeList="0: gas phase HR;1: gas phase UMR;2: FIGAERO thermograms;3: FIGAERO integrated mass spectra;"
	TypeList+="4: aerosol HR using family colour coding (no elemental ratios);5: aerosol HR with elemental ratios (AMS & ACSM);"
	TypeList+="6: aerosol UMR;7: aerosol UMR old ACSM (error downweighing already done);8: aerosol UMR old Q AMS;"
	
	Note PMFSolInfo, Typelist	// note for wave
	
	Prompt dataTypeNum,"Select data type for PMFsolinfo Wave:",popup, typeList
	
	DoPrompt/Help=HelpStr "Data Type",dataTypeNum
	
	IF (V_flag==1)	// user canceled
		abort
	ENDIF
ENDIF

PMFSolInfo[5]=num2str(dataTypeNum-1)
	

END

//======================================================================================
//======================================================================================

// Purpose:	calculate the idxSample values (start and end row of each samplein th ecombined data set) from the Tdesorp vlaues
//				assuming that there is a 15-20C gap between Tdesorp ramps of samples
//				
// Input:		IDXSampleName:	String with name for idxSample wave (can contain full path)
//				Tdesorp:			wave with Tdesorp values
//				
// Output:	Wave with IDXsample values at given location

FUNCTION MPaux_makeIDXsample(IDXSampleName,Tdesorp)

String IDXsampleName
Wave Tdesorp

// separate experiments (using changes in tseries assuming 20 - 200C as maximum scan range)
Variable delta = 15

Make/O/D/N=(numpnts(Tdesorp)-1) diffT, idxW=NaN
diffT= Tdesorp[p+1]-Tdesorp[p]
idxW = abs(diffT) >delta? p : NaN	// find step between scans (should be ~20C), last point of scan
Wavetransform  zapnans idxW
InsertPoints 0,1,idxW
idxW[0]=-1
InsertPoints numpnts(idxW),1,idxW
idxW[numpnts(idxW)-1]=numpnts(Tdesorp)-1

Make/O/D/N=(numpnts(idxW)-1,2) $(IdxSampleName)	// first column: start of thermogram
Wave/D idxSample=$(IdxSampleName)
idxSample[][1]=idxW[p+1]
idxSample[][0]=idxW[p]+1

Killwaves/Z idxW,DiffT

END

//======================================================================================
//======================================================================================

// Purpose:	set the warning text in MaS-PET when ACSM or AMS MS type is chosen
//				
// Input:		type: 1: old ACSM, 0 all other aerosol stuff 
//				
// Output:	adjust the labels Title_label2_5,Title_label2_6,Title_label2_7

FUNCTION MPaux_SetWarning(type)
VAriable Type	

String label2_5_str="\K(65280,0,0)ATTENTION: You must use 'Prep' tab in PET panel for data prep!"
String label2_6_str="return to MaS-PET Panel after finishing all downweighing"
String Label2_7_str="or continue with PET panel for more parameters for calculations"

// change for old ACSM which has al error downweighing done already
IF (Type==1)
	label2_5_str="\K(65280,0,0)ATTENTION: Error Downweighing already done in ACSM software!"
	label2_6_str="only check for NaNs/zeros before running PMF"
	Label2_7_str="or go to PET 'run panel' for more parameters for calculations"
ENDIF

TitleBox Title_label2_5 title=Label2_5_str,win=MaSPET_panel
TitleBox Title_label2_6 title=label2_6_str,win=MaSPET_panel
TitleBox Title_label2_7 title=label2_7_str,win=MaSPET_panel

END

//======================================================================================
//======================================================================================

// Purpose:	convert Tdesorp with i*200 offset back to real Tdesorp values
//				
// Input:		Tdesorp_offset:	Wave with Tdesorp with offset
//				IDXSample:		Sample IDX wave with start and endpoint of each sample
//				offset:			value of offset to be removed (typical 200)
// Output:	Tdesorp_real wave with real Tdesorp values

FUNCTION MPaux_ResetTdesorpOffset(Tdesorp_offset,IDXSample,offset)

Wave Tdesorp_offset
Wave IDXSample
Variable offset

// make new Tdesorp Wave
String OffsetName=GetWavesDataFolder(Tdesorp_Offset,2)
String RealName=OffsetName+"_real"

Make/D/O/N=(numpnts(Tdesorp_offset)) $(RealName)
Wave Tdesorp_real=$RealName

// loop through idxSample entries
Variable ii
FOR (ii=0;ii<dimsize(IDXsample,0);ii+=1)
	
	Tdesorp_real[IdxSample[ii][0],IdxSample[ii][1]]=Tdesorp_offset[p]-ii*offset		// subtract offset

ENDFOR

// print info
print "-----------------"
print "Removed offset of i*"+num2str(offset)+" from wave: "+Offsetname
print "New Wave: "+RealName
print "To use this wave, change the wave name in the MaS-PET panel to: "+ Stringfromlist(Itemsinlist(realName,":")-1,realName,":")
print "-----------------"

END

//======================================================================================
//======================================================================================

//=============================================
//		procedures for checking for objects
//=============================================

//======================================================================================
//======================================================================================

// Purpose:	check if all waves selected in Panel are present, have matching dimensions, and are of right type (numeric/text)
//				
// Input:		foldername:	string name of datafolder to operate on							
//				waveNames:	txt Wave with names for data waves 
//								!!! must have the standard names as dimension labels !!!
//								empty field will be ignored for MSerr entry
//				quiet:			1: no output in command window
//				ignoreErr:	do not look at MSerr Wave
//				
//
// Output:	abort and abort message if there is any problem
//				if no problem was found and quiet=0 -> ok message in command window

FUNCTION MPaux_checkPMFWaves(foldername,waveNames,quiet,[ignoreErr])

String FolderName
Wave/T Wavenames
Variable Quiet
Variable IgnoreErr
Variable MStype

Variable Ignore	// 0: use all waves, 1: ignore MSerr entry
IF (Paramisdefault(ignoreErr))
	Ignore=0
ELSE
	Ignore=IgnoreErr
ENDIF

SVAR abortStr=root:APP:abortStr

Variable test1=0,test2=0,test3=0,test4=0


//-----------------------------------
// check if everything exists (and names were put into fields)

// check if combi folder exists
IF (!datafolderexists(folderName))
	abortStr="MPaux_checkPMFWaves():\r\rno datafolder found with name "+foldername
	MPaux_abort(abortStr)
ENDIF

// put data waves into string list
String List_waves=""
Variable ww=0

String EmptyFields=""

FOR (ww=0;ww<numpnts(WaveNames);ww+=1)
	
	String CurrentLabel=Getdimlabel(Wavenames,0,ww)

	IF (!stringmatch(Wavenames[ww],""))	// catch empty field (usually MSerrName)
		
		IF (!Stringmatch(CurrentLabel,"FigTimeName"))	//skip Fig time series wave
			
			// check if MSerr should be skipped
			IF(Ignore==0)
				// check
				list_waves+=folderName+":"+Wavenames[ww]+";"
			ELSE
				// skip
				IF (!StringMatch(CurrentLabel,"MSErrName"))
					list_waves+=folderName+":"+Wavenames[ww]+";"
				ENDIF
			ENDIF
			
		ENDIF

	ELSE
		// write waves with empty fields here
		STRSWITCH (Currentlabel)
			CASE "MSerrName":
				// only complain if set
				IF (Ignore==0)
					EmptyFields="Error Matrix;"			
				ENDIF
				BREAK
			//ignore FigTimeName
			CASE "FigTimeName":
				BREAK	
			// everything else is important
			CASE "MSdataName":
				EmptyFields="Mass SPec data;"	
				BREAK
			CASE "TName":
				EmptyFields="time series/Tdesorp;"	
				BREAK
			CASE "MZName":
				EmptyFields="MZ values (NUM);"	
				BREAK
			CASE "LAbelName":
				EmptyFields="ion names (TXT);"	
				BREAK
			DEFAULT:
				BREAK
		ENDSWITCH
		
	ENDIF
ENDFOR

// missing names
IF(itemsinlist(EmptyFields)>0)
	abortStr="MPaux_checkPMFWaves():\r\rSome wave names are not set in the MaS-PET Panel:"
	
	FOR (ww=0;ww<itemsinlist(EmptyFields);ww+=1)
		abortStr+="\r"+Stringfromlist(ww,EmptyFields)
	ENDFOR
	
	MPaux_abort(abortStr)
ENDIF

// check for waves
test1=MPaux_checkWavesFromlist(list_waves)

Wave/Z nonexistIDX

IF (test1<1)	
	abortStr="MPaux_checkPMFWaves():\r\rmissing waves in folder "+foldername
	// add missing waves to abort Str
	FOR (ww=0;ww<numpnts(NonExistIdx);ww+=1)
		abortStr+="\r"+Stringfromlist(NonexistIdx[ww],LIst_waves)
	ENDFOR
	
	Killwaves/Z nonExistIDX
	
	MPaux_abort(abortStr)
ENDIF

IF (quiet==0)
	print " + all selected waves are present in folder: "+foldername
ENDIF

//-----------------------------------
// check if waves have the right dimension

Wave/Z MSdata=$(folderName+":"+Wavenames[%MSdataName])
Wave/Z MSerr=$(folderName+":"+Wavenames[%MSerrName])
Wave/Z exactMZ=$(folderName+":"+Wavenames[%MZName])
Wave/T/Z ionLabel=$(folderName+":"+Wavenames[%LabelName])
Wave/Z Tdesorp=$(folderName+":"+Wavenames[%TName])
String Errorname=Wavenames[%MSerrName]

abortStr="MPaux_checkPMFWaves():\r\r"	// reset abortStr to this function
String abortStr1=""

// check MSerr and MSdata are 2D
IF (WaveDims(MSdata) !=2)
	test2+=1
	abortstr+="MS data wave is: "+num2Str(WaveDims(MSdata))+"D. It must be 2D!\r"
	abortStr+=folderName+":"+Wavenames[%MSdataName]+"\r"
ENDIF

IF (!stringmatch(Errorname,""))	// skip MSerr if field is empty
	IF (Ignore==0)	// ignore if asked
		IF (WaveDims(MSerr) !=2)
			test2+=1
			abortstr+="MS error wave is: "+num2Str(WaveDims(MSerr))+"D. It must be 2D!\r"
			abortStr+=folderName+":"+Wavenames[%MSerrName]+"\r"
		ENDIF
	ENDIF
ENDIF

// exactMZ, ionlabel, Tdesorp are 1D
IF (WaveDims(exactMZ) !=1)
	test2+=1
	abortstr+="exactMZ wave is: "+num2Str(WaveDims(exactMZ))+"D. It must be 1D!\r"
	abortStr+=folderName+":"+Wavenames[%MZName]+"\r"
ENDIF

IF (WaveDims(ionLabel) !=1)
	test2+=1
	abortstr+="ionLabel wave is: "+num2Str(WaveDims(ionLabel))+"D. It must be 1D!\r"
	abortStr+=folderName+":"+Wavenames[%LabelName]+"\r"
ENDIF

IF (WaveDims(Tdesorp) !=1)
	test2+=1
	abortstr+="Tdesorp wave is: "+num2Str(WaveDims(Tdesorp))+"D. It must be 1D!\r"
	abortStr+=folderName+":"+Wavenames[%TName]+"\r"
ENDIF

// report results of wave dimension check
IF (test2>0)
	MPaux_abort(abortStr)
ENDIF

//-----------------------------------
// check if waves dimensions agree

// check MSdata and MSerr
Variable noc=dimsize(MSdata,1)	// number of columns=ions
Variable nor=dimsize(MSdata,0)	// number of rows=
IF  (!stringmatch(Errorname,""))
	IF (Ignore==0)
		IF (dimsize(MSerr,0)!=nor || dimsize(MSerr,1)!=noc)
			abortStr+="\rnumber of columns or rows does  not agree between data and error matrix:\r"
			abortStr+=folderName+":"+Wavenames[%MSdataName] +"\r" +folderName+":"+Wavenames[%MSerrName]+"\r"
			test3+=1
		ENDIF
	ENDIF
ENDIF
// check MSdata and exactMZ
IF (numpnts(exactMZ)!=noc )
	abortStr+="\rnumber of columns in data matrix does  not agree with exactMZ wave:\r"
	abortStr+=folderName+":"+Wavenames[%MSdataName] +"\r" +folderName+":"+Wavenames[%MZname]+"\r"
	test3+=1
ENDIF

// check MSdata and ionlabel
IF (numpnts(ionLabel)!=noc)
	abortStr+="\rnumber of columns in data matrix does  not agree with ionLabel wave:\r"
	abortStr+=folderName+":"+Wavenames[%MSdataName] +"\r" +folderName+":"+Wavenames[%labelname]+"\r"
	test3+=1
ENDIF

// check MSdata and Tdesorp
IF (numpnts(Tdesorp)!=nor)
	abortStr+="\rnumber of rows in data matrix does  not agree with Tdesorp wave:\r"
	abortStr+=folderName+":"+Wavenames[%MSdataName] +"\r" +folderName+":"+Wavenames[%Tname]+"\r"
	test3+=1
ENDIF

// report result of wave comparison check
IF (test3>0)
	MPaux_abort(abortStr)
ENDIF

IF (quiet==0)
	print " + dimensions of chosen waves agree"
ENDIF

//--------------------------------------
// check wave types

Variable ii
String CurrentWavename=""
String dummyWaveNames="MS data;MS error;MZ values;ion Label;T/time series;"

// find ion label wavename entry
Variable IDXlabel=FindDimLabel(Wavenames,0,"LabelName")
IF (IDXlabel<0)
	abortStr="MPaux_checkPMFWaves():\r\rproblem with dimension labels of Wavenames wave. 'LabelName' not found.\r"
	abortStr+=GetwavesDatafolder(Wavenames,2)
	
	MPaux_abort(abortStr)
ENDIF

FOR(ii=0;ii<itemsinlist(dummyWaveNames);ii+=1)	

	CurrentWavename=folderName+":"+	Wavenames[ii]

	IF (ii!=3)	// all waves apart from ion label one
		// check if numeric
		IF(Wavetype($CurrentWavename,1)!=1)	
			IF (ignore==0)	// test all
				test4+=1
				abortSTr+=Stringfromlist(ii,dummyWaveNames)+" wave must be numeric:\r"
				abortStr+=folderName+":"+Wavenames[ii] +"\r"
			ELSE
				// do not test MSerr
				IF (ii!=1)	// do not test MSerr
					test4+=1
					abortSTr+=Stringfromlist(ii,dummyWaveNames)+" wave must be numeric:\r"
					abortStr+=folderName+":"+Wavenames[ii] +"\r"
				ENDIF
			ENDIF
		ENDIF	
		
	ELSE	// if ion label (=>Wavenames[3])
		// check if it is text
		IF(Wavetype($CurrentWavename,1)!=2)
			test4+=1
			abortStr+="ion label wave is NOT of type text\r"
			abortStr+=folderName+":"+Wavenames[ii] +"\r"
		ENDIF
		
	ENDIF

ENDFOR

// report results of wave dimension check
IF (test4>0)
	MPaux_abort(abortStr)
ENDIF

IF(quiet==0)
	print " + Wave types are ok"
ENDIF

// reset abortStr to empty
abortStr=""

END

//======================================================================================
//======================================================================================

// Purpose:	check if all waves in a stringlist do exist (data folder is not changed)
// Input:		nameList	: stringlist with wavenames
// 				
// Output :	returns 1 if all waves exist
//				returns 0 if at least one wave does not exist 
//				returns -1 if something was wrong
//				NonExistIdx	wave with numbers of non existing waves

FUNCTION/D MPaux_CheckWavesFromList(NameList)

String NameList

Variable check =-1	// return value

// check if string contains a list

Variable ii
Make/FREE/N=(itemsinlist(Namelist)) temp=nan
IF (itemsinlist(NameList)==1)
	print "MPaux_CheckWavesFromList(): only one item found in passed NameList -> check input if this is a problem"	
ELSE

	FOR (ii=0;ii<itemsinlist(NameList);ii+=1)
		IF(!waveexists($stringfromlist(ii,namelist)))	// wave does NOT exists
			check=0
			temp[ii]=ii	// store index number
		ENDIF

	ENDFOR
	// remove empty entries
	Wavetransform zapnans temp
	IF (numpnts(temp)==0)	// no entries=all waves exist
		check=1
	ELSE
		Make/O/D/N=(numpnts(temp)) NonExistIdx=temp
	ENDIF

ENDIF

RETURN check

END

//======================================================================================
//======================================================================================

// Purpose:	check if all SVAR or NVAR in a stringlist do exist (data folder is not changed)
// Input:		nameList	: stringlist with wavenames
// 				
// Output :	returns 1 if all waves exist
//				returns 0 if at least one wave does not exist 
//				returns -1 if something was wrong
//				NonExistIdx	wave with numbers of non existing waves

FUNCTION/D MPaux_CheckVARFromList(NameList)

String NameList

Variable check =-1	// return value

// check if string contains a list

Variable ii
Make/FREE/N=(itemsinlist(Namelist)) temp=nan
IF (itemsinlist(NameList)==1)
	print "MPaux_CheckWavesFromList(): only one item found in passed NameList -> check input if this is a problem"	
ELSE

	FOR (ii=0;ii<itemsinlist(NameList);ii+=1)
	
		NVAR/Z DummyNVar=$stringfromlist(ii,namelist)
		
		IF(!NVAR_Exists(DummyNVar))	// no numeric variable exists
			
			// try if it is a string variable
			SVAR/Z DummySVar=$stringfromlist(ii,namelist)
			
			IF (!SVAR_exists(DummySVAR))
				check=0
				temp[ii]=ii	// store index number
			ENDIF
			
		ENDIF

	ENDFOR
	// remove empty entries
	Wavetransform zapnans temp
	IF (numpnts(temp)==0)	// no entries=all waves exist
		check=1
	ELSE
		Make/O/D/N=(numpnts(temp)) NonExistIdx=temp
	ENDIF

ENDIF

RETURN check

END


//======================================================================================
//======================================================================================

// Purpose:	check if there is an entry for the MSerr wave in Wavenames
//				if not put MSerr there
// Input:		Wavenames:	text wave with names ofdata waves in FITPET panel
// 				
// Output :	adds a MSerrName to Wavenames Wave

FUNCTION MPaux_CheckMSerrName(Wavenames)

Wave/T Wavenames

IF (Stringmatch(Wavenames[%MSerrname],""))
	print "-----------------"
	print "MPaux_CheckMSerrName(): MSerror name field was empty -> setting it to MSerr"
	Wavenames[%MSerrname]="MSerr"
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	check if Wavename is too long
//				prompt user for different Name
// Input:		testname:	String to be tested
// 				
// Output :	returns either original or new wavename
//				if user canceled or name is still too long, empty string is returned

FUNCTION/S MPaux_checkNameLength(testName)

String Testname

String NewName	// name to be reported

Variable TestLength=0
Variable MaxLength=31

IF (Igorversion()>=8.00)
	MaxLength=254
ENDIF

// check length
IF (strlen(testName)<=MaxLength)
	//everything ok
	newName=testName
	
ELSE
	// too long
	TestLength+=1
	
	// prompt user for new verison
	String tooLongName=testname
	Prompt tooLongName,"Name was too long. Reduce by "+num2str(MaxLength-strlen(testName))
	DoPrompt "Wave name length" toolongname

	IF (V_flag==1)
		// user cancelled
		NewName=""
	ELSE
		// check again
		IF (strlen(toolongname)>MaxLength)
			newName=""
			print "new name is still too long by " +num2Str(MaxLength-strlen(toolongname))+" characters -> aborting"
		ELSE
			newName=tooLongName
		ENDIF
	ENDIF		

ENDIF

RETURN NewName

END

//======================================================================================
//======================================================================================

// Purpose:	check if all folders given in Exp list exist
// Input:		nameList	: name of Wave with Explist 
// 				
// Output :	returns 1 if all folders exist
//				returns 0 if at least one wave does not exist 
//				returns -1 if something was wrong
//				NonExistIdx	wave with numbers of non existing waves

FUNCTION/D MPaux_CheckExpListFolders(ExpListname)

String ExpListname

Variable check =-1	// return value

// check if wave exists
IF (!Waveexists($ExpListName))
	print "-----------------"
	print "MPaux_CheckExpListFolders(): No wave found with name: "+ExpListName
	RETURN check
ENDIF

Wave/T ExpList=$ExpListName

Variable ii
Make/FREE/N=(numpnts(ExpList)) temp=nan

FOR (ii=0;ii<numpnts(ExpList);ii+=1)

	IF(!datafolderexists(ExpList[ii]))	// wave does NOT exists
		check=0
		temp[ii]=ii	// store index number
	ENDIF

ENDFOR

// remove empty entries from index wave
Wavetransform zapnans temp
IF (numpnts(temp)==0)	// no entries=all folders exist
	check=1
ELSE
	Make/O/D/N=(numpnts(temp)) NonExistIdx=temp
ENDIF

RETURN check

END


//======================================================================================
//======================================================================================

// Purpose:		check if IDXSample Wave exists and if not ask user what to do	

// Input:			IdxSampleName:	string name of wave containing IDX_sample information
//					FolderStr:		current folder name
//					Tdesorp:			Wave with Tdesorp (or tseries) values
//					ExpList:			txt wave with names of experiments
// Output:		idxSample wave inside FolderStr folder
//
// called by:	multiple functions


FUNCTION MPaux_check4IDXSample(IdxSampleName,FolderStr,Tdesorp,ExpList)

String IdxSampleName
String FolderStr
Wave Tdesorp
Wave/T expList

// get abortStr
SVAR/Z abortStr=root:app:abortStr
String alertStr=""

// check if IdxSample wave exists
IF (Waveexists($(FolderStr+":"+idxSampleName)))
	Wave/D idxSample=$(FolderStr+":"+idxSampleName)
ELSE
	// check with user what to do
	alertStr="wave '"+IdxSampleName+"' not found in folder: \r"+FolderStr
	alertStr="\r\rDo you want to:"
	alertStr+="\r\r[YES] Identify samples from data useing full data range as 1 sample?\r\r"
	alertStr+="[NO] Or assuming desorption Temperature ranges from 20-200C?"
	doAlert 2,alertstr 
	
	// user canceled
	IF (V_flag==3)
		abort
	ENDIF

	// recalculate assuming FIGAERO thermogram data
	IF (V_flag==2)
		String IDXsampleStr=FolderStr+":"+IdxSampleName
		MPaux_makeIDXsample(IDXsampleStr,Tdesorp)
		Wave idxSample=$IDXsampleStr
		
		// show user in table
		Killwindow/Z IDXsampleCalculation
		edit/k=1/N=IDXsampleCalculation Tdesorp,idxSample,ExpList as "IDXsampleCalculation"
	ENDIF
	
	// use full data set as one sample
	IF (V_flag==1)
		Make/O/D/N=(1,2) $(FolderStr+":"+IdxSampleName)
		Wave/D idxSample=$(FolderStr+":"+IdxSampleName)
		idxSample={{0},{numpnts(Tdesorp)-1}}
	ENDIF
	
ENDIF

// check number of sample vs explist wave
IF (dimsize(idxSample,0) != numpnts(explist))
	
	Killwindow/Z IDXsampleCalculation
	edit/k=1/N=IDXsampleCalculation Tdesorp,idxSample,ExpList as "IDXsampleCalculation"
	
	abortStr="MPaux_check4IDXSample():\r\r "
	abortStr+="Number of samples in IdxSample Wave ("+num2str(dimsize(idxSample,0))+") does not agree with number of sample in ExpList wave ("+num2str(numpnts(Explist))+")"
	MPaux_abort(abortStr)		
ENDIF

// check if maximum value in idxSample is within Tdesorp dimension
IF(Wavemax(idxSample) > numpnts(Tdesorp)-1)
	Killwindow/Z IDXsampleCalculation
	edit/k=1/N=IDXsampleCalculation Tdesorp,idxSample,ExpList as "IDXsampleCalculation"
	
	abortstr="MPaux_check4IDXSample():\r\rLargest entry in idxSample wave is bigger than number of rows in data set. \r=>Check Input."
	MPaux_abort(abortStr)		
ENDIF


END

//======================================================================================
//======================================================================================

// Purpose:		check if Waves4PMF wave exists and if not ask user what to do	
//					user is prompted to provide names for a new Waves4PMF wave
//
// Input:			FolderStr:	current folder name
//					ctrlName:		name of button cointrol that called the check (for abort message)
//					Wavenames:	text wave with wavenames from panel
// Output:		Waves4PMF wave in selected folder
//					 
// called by:	multiple functions

FUNCTION MPaux_check4Waves4PMF(FolderStr,ctrlName,Wavenames)

String folderStr
String ctrlName
Wave/T wavenames

// abortStr
SVAR abortStr=root:APP:abortSTr

// search for wave		
Wave/T/Z Waves4PMF=$(folderStr+":Waves4PMF")
			
IF (!Waveexists(Waves4PMF))
	// store info about issue
	print "-------------------------"
	print date() +" "+time()+" checking for Waves4PMF wave"
	print "MPbut_step3_button_control: - "+ctrlName
	print "Waves4PMF wave does not exist in folder "+folderStr
	print "-> creating new Waves4PMF wave "
	
	abortSTr="MPbut_step3_button_control: - "+ctrlName+"\r\r" + folderStr+":Waves4PMF"+" does not exists and user canceled"

	// set new wavenames	
	MPaux_Prompt4Wavesnames(folderStr,Wavenames,ctrlName,1)
	Wave/T Wavenames_temp=$(folderStr+":Wavenames_temp")
	
	MPaux_MakeWaves4PMF(folderStr,Wavenames_temp)
	Wave/T Waves4PMF=$(folderStr+":Waves4PMF")
	
	Killwaves/Z Wavenames_temp
ENDIF


END

//======================================================================================
//======================================================================================

// Purpose:		Check if TimeStamp Wave exists in FactorContrib_Tmax subfolder of FolderStr
// Input:			FolderStr:		Name of current PMF solution folder
//					TimeStampName:	Name of Time Stamp wave
//					FIGtseriesName:	Name of wave with FIGAERO time series, set "" if wave does not exist
// Output:		1: Time stamp wave exists and passes basic check
//					0: some problem, time stamp wave does not exist
//					If selected TimeStamp wave will be loaded from text
//
// called by:	multiple functions TimeStamp Wave is needed for bar plot and diurnal pattern

FUNCTION MPaux_Check4TimeStamp(FolderStr,TimeStampName,FigTseriesName)

String FolderStr
String TimeStampName
String FigTseriesName	

SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF
String AlertStr=""

FolderStr=removeending(FolderStr,":")

Wave/D timeStamp=$(FolderStr+":FactorContrib_Tmax:"+TimeStampName)

String oldFolder=getdatafolder(1)
		
IF (Waveexists(timeStamp))
	// time stamp wave was found
	RETURN 1
ENDIF

// no time stamp wave found

// check if Fig. time series wave is there
Variable DoALertType=2
alertStr="The wave "+TimeStampname+" not found"
alertStr+="\rDo you want to:"
alertStr+="\r\r[YES] Load time stamps for samples from text file?"
alertStr+="\r(Time stamp values in file must be 1 column of Igor or matlab seconds)"

// if FIG tim series exists
String FigTimepath=folderstr+":"+FigTseriesName
figtimepath=replacestring("::",FigTimepath,":")

IF (Waveexists($figtimepath))		
	alertStr+="\r\r[NO] Extract them from Fig. Time Series Wave?"
ELSE
	doAlertType=1
	alertStr+="\r\r[NO] Abort?"
ENDIF

doalert doalertType,alertStr

// YES -> load from file
IF (V_Flag==1)
	
	// prompt for file
	Variable refNum
	String Message="Select txt file with sample Time stamps"
	String fileFilters = "Data Files (*.txt):.txt;"
	fileFilters += "All Files:.*;"

	Open /D/R/F=fileFilters /M=message refNum	// open file selection dialog

	String FileName = S_fileName	
	
	IF (stringmatch(Filename,""))	// user canceled
		AbortStr="MPaux_Check4TimeStamp():\r\rno TimeStamp wave found and user aborted"
		RETURN 0		
	ENDIF
		
	Setdatafolder root:
	
	Setdatafolder $(FolderStr+":FactorContrib_Tmax")
	Loadwave/O/A/Q/D/J/K=1/B=("N=TimeStamp;") fileName
	
	Wave/D timeStamp=timeStamp
	Wave TestWave=FactorContrib_abs
	
	// check if it fits number of samples
	IF (numpnts(timeStamp)!=dimsize(TestWave,0))	// number of samples
		// check if it has 1 extra row due to header in txt file
		IF (numpnts(timeStamp)-1==dimsize(TestWave,0) && numtype(timeStamp[0])==2)
			deletepoints 0,1, timeStamp			
		ELSE	
			abortStr = "MPaux_Check4TimeStamp():\r\rentries in timeStamp wave loaded from text file do not match number of samples in factor contribution wave."
			abortStr+="\rCurrent Load saved as Wave TimeStamp_temp."
			
			// display problematic wave
			Duplicate/O TimeStamp,TimeStamp_temp
			Killwindow/Z TimeStamp_Table
			Edit/K=1/N=TimeStamp_Table TimeStamp_temp,TestWave as "TimeStamp_Table"
			Killwaves/Z TimeStamp	// delete TImeStamp wave to ensure that Loading will be triggered again
			
			Setdatafolder $oldFolder
			
			RETURN 0
		ENDIF
	ENDIF
	
	// check input format
	IF (numtype(timeStamp[0])!=0)	// is it numerical?
		abortSTr="Check4TimeStamp:\r\rloaded timeStamp wave contains NaN -> check input"
		Setdatafolder $oldFolder
		RETURN 0
	ENDIF
			
	IF (timeStamp[0]>7e5 && timestamp[0]<1e9)	//matlab or Igor seconds?
		duplicate/FREE/D timeStamp,timeStamp1
		timeStamp=MPaux_Matlab2IgorTime(timeStamp1)
	ENDIF
	
	Setscale d 0,0,"dat", timeStamp
	
	// remove any leftover temporary wave
	Killwindow/Z TimeStamp_Table
	Killwaves/Z TimeStamp_temp	
	
	Setdatafolder $oldFolder

	RETURN 1
ENDIF

// NO -> get time stamp from Fig. tseries wave 
IF (V_Flag==2 && doalertType==2)
	
	Setdatafolder $(FolderStr)
	
	// get time series wave
	Wave FigTseries=$FigTseriesName
	
	// get Sample index (this needs MaSPET!!!)
	Wave/Z IDXSample=IDXSample
	
	IF (!Waveexists(IDXSample))	// if IDX sample does not exist
		abortstr ="IDXSample wave is needed to determine timestamp values from the Fig. time series Wave."
		abortstr+="\rUse MaS-PET V>2.0 to export PMF solutions to make sure IDXSample exists."
		abortSTr+="\rOr manually create a 2 column wave with name 'IDXsample' with the start and end index of each sample in the solution folder."
		MPAux_abort(abortSTR)
	ENDIF
	
	// create timestamp wave
	Setdatafolder $(FolderStr+":FactorContrib_Tmax")
	
	Make/D/O/N=(dimsize(idxsample,0)) $(TimeStampName)
	Wave TimeStamp=$TImeStampName
	
	Variable ii
	FOR(ii=0;ii<numpnts(TimeStamp);ii+=1)
		TimeStamp[ii]=FigTseries[idxSample[ii][0]]
	ENDFOR
	
	SetScale d 0,0,"dat", timestamp
ENDIF

// CANCEL -> abort || NO -> abort
IF (V_Flag==2 && doalertType==1)
	// abort
	Setdatafolder $oldFolder
	abortStr="Check4TimeStamp:\r\rno TimeStamp wave found and user aborted"
	
	RETURN 0

ENDIF

IF (V_flag==3)
	abortStr="Check4TimeStamp:\r\rno TimeStamp wave found and user aborted"
	Setdatafolder $oldFolder
	
	RETURN 0
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		check if old FiT-PET was used for exporting solutions -> fix Wave names for MaSPET
//					this is for factor mass spec and time series/Thermorams
// Input:			solName:	Full Path of exported solution folder	
// Output :		Dialog to ask user what to do
//					If selected: copy of factor MS and TS to match MaS-PET format
//					return value: 	1: everything is fine
//										0: no waves found, user aborted
//										-1:	no waves found, must abort
//										-2: datafolder not found
//					abort must be handled at top layer
// called by:	multiple functions operating on extracted solution folder

FUNCTION MPaux_check4FitPET_MSTS(solName)

String solName

// check if datafolder exists
IF (!datafolderExists(solName))
	RETURN -2
ENDIF

// check if waves have MaSPET names (use first factor -> should always be there)
String CurrentWaveStr=solName+":Factor_TS1"
currentwaveStr=replaceString("::",currentWaveStr,":")
// wave is found -> do nothing
IF (Waveexists($currentWaveStr))
	RETURN 1
ENDIF

// wave not found -> check if old FITPET names exist
currentwaveStr=replaceString("Factor_TS1",currentWaveStr,"factorThermo1")

IF (Waveexists($currentWaveStr))
	// prompt user
	String AlertStr=""

	AlertStr="Waves of type 'Factorthermo1' and FactorMS1_rel' found instead of 'Factor_TS1' and 'Factor_MS1' "
	AlertStr+="in folder:\r"+solName
	ALertStr+="\r\rUse these Waves (YES) or abort (NO)?"
	DoAlert 1,alertStr
	
	IF (V_flag==1)	// yes
		
		String oldFolder=getdatafolder(1)
		Setdatafolder $solName
		
		// get solution number
		Variable nsol=0
		String MSlist=wavelist("FactorMS*_rel",";","")
		nsol=itemsinlist(MSlist)
		
		// loop through factors and make copy with MaS-PET names
		Variable ii
		FOR (ii=0;ii<nsol;ii+=1)
			// original names
			String oldMSname="FactorMS"+num2str(ii+1)+"_rel"
			String oldTSname="FactorThermo"+num2str(ii+1)
			// new names
			String newMSname="Factor_MS"+num2str(ii+1)
			String newTSname="Factor_TS"+num2str(ii+1)
			//old Waves
			Wave MSold=$oldMSName
			Wave TSold=$oldTSname
			// copy with new names
			duplicate/O MSold, $newMSname
			duplicate/O TSold, $newTSname
			// reset wave names
			Wave MSold=$""
			Wave TSold=$""
			
		ENDFOR

	print "------------------"
	print date() + " " + time() + " old FiT-PET extracted solution conveted to new MaS-PET format:"
	print solname
	
	Setdatafolder $oldfolder
	
	RETURN 1

	ELSE	// NO
		RETURN 0
	ENDIF	

ELSE

	// no old fitpet names found
	RETURN -1
	
ENDIF


END

//======================================================================================
//======================================================================================

// Purpose:		check if old FiT-PET was used for exporting solutions -> fix Wave names for MaSPET
//					this is for the sample by sample waves
//					uses sampleName_Farea waves for check (least likely to have other waves with _Farea ending)
// Input:			solName:	Full Path of exported solution folder
//						
// Output :		Dialog to ask user what to do
//					If selected: copy data to data bysample folder
//					return value: 	1: everything is fine
//										0: no waves found, user aborted
//										-1:	no waves found, must abort
//										-2: datafolder not found
//										-3 databysample folder exists but no waves inside
//
//					abort must be handled at top layer
// called by:	multiple functions operating on extracted solution folder

FUNCTION MPaux_check4FitPET_bysample(solName)

String solName

String FareaList=""
String oldfolder=getdatafolder(1)

// check if datafolder exists
IF (!datafolderExists(solName))
	RETURN -2
ENDIF

// check if waves were sorted into DataSortedBySample subfolder
Setdatafolder $solname

String SubfolderStr=solname+":DataSortedBySample"
SubfolderStr=replaceString("::",SubfolderStr,":")

IF (datafolderexists(SubfolderStr))	

	Setdatafolder $SubfolderStr

	// check if waves exist
	FareaList=Wavelist("*_Farea",";","")
	IF (Itemsinlist(FareaList)>0)
		// at least one wave found
		RETURN 1
	ELSE
		// no waves were found
		RETURN -3
	ENDIF
ENDIF

// check main results folder for waves and copy
Setdatafolder $solname

FareaList=Wavelist("*_Farea",";","")	// now search in main results folder
Variable nSample=Itemsinlist(FareaList)

IF (nSample>0)
	
	// prompt user
	String AlertStr=""

	AlertStr="Sample by sample data detected in main results folder:"
	AlertStr+="\r"+solName
	ALertStr+="\r\rCopy these Waves to 'DataSortedBySample' subfolder (YES) or abort (NO)?"
	DoAlert 1,alertStr
	
	IF (V_flag==1)	// yes
		// experiment list wave
		Make/T/O/N=(nSample) Explist4PMF=""
		Note Explist4PMF, "This wave is not used for the plotting procedures. The Explist selected in the MaS-PET panel is used instead!" 
		
		// make subfolder
		Newdatafolder/O DataSortedBySample 
		
		// loop through factors and make copy with MaS-PET names
		Variable ii
		FOR (ii=0;ii<nsample;ii+=1)
			// original names
			String oldFareaName=Stringfromlist(ii,FareaList)
			String oldTmaxname=replacestring("_Farea",oldFareaName,"_Tmax")
			String oldThermosname=replacestring("_Farea",oldFareaName,"_Thermos")
			// new names
			String newFareaname=":DataSortedBySample:"+oldFareaName
			String newTmaxname=":DataSortedBySample:"+oldTmaxname
			String newThermosName=":DataSortedBySample:"+oldThermosname
			newThermosName=replacestring("_Thermos",newThermosName,"_TS")
			
			// original Waves				
			Wave Fareaold=$oldFareaName
			Wave Tmaxold=$oldTmaxname
			Wave Thermosold=$oldThermosname
			// duplicate in new location
			duplicate/O Fareaold, $newFareaname
			duplicate/O Tmaxold, $newTmaxname
			duplicate/O Thermosold, $newThermosName
			
			// reset names
			Wave Fareaold=$""
			Wave Tmaxold=$""
			Wave Thermosold=$""
			
			// Explist name
			ExpList4PMF[ii]=removeending(oldFareaName,"_Farea")
			
		ENDFOR

	print "------------------"
	print date() + " " + time() + " old FiT-PET extracted solution conveted to new MaS-PET format:"
	print solname
	
	Setdatafolder $oldfolder
	
	RETURN 1

	ELSE	// NO
		RETURN 0
	ENDIF	

ELSE

	// no old fitpet names found
	RETURN -1
	
ENDIF


END

//======================================================================================
//======================================================================================

// Purpose:		check if folder Name is too long for Igor 6 and return

// Input:			mainFolder:	name of top level folder in which to create the new subfolder
//					subfolder:	desired name of subfolder
//					baseName:		use this basic name with number to create unique folder name if chosen name is too long
// Output:		NewFOlder:	either desired subfolder name OR adjusted folder name to match length criteria
//
// called by:	multiple functions

FUNCTION/S MPaux_folderName(mainFolder,subfolder,baseName)

String mainFOlder
String subfolder
String baseName

String newFolder=subFolder

Variable maxlength=254	// max length in Ior >8
IF (Igorversion()<8.0)
	maxLength=31
ENDIF

IF (strlen(subfolder)>maxlength)
	String oldfolder=getdataFolder(1)
	Setdatafolder $mainFolder	// go to right datafolder
	subfolder=UniqueName(baseName,11,0)
	Setdatafolder $oldFolder
ENDIF

RETURN NewFolder
 
END

//======================================================================================
//======================================================================================

	
//========================================
//		panel aux  procedures
//========================================

//======================================================================================
//======================================================================================

// Purpose:	check if wave(s) exists and make a table with them
//				
// Input:		WaveName_list:	String name of txt wave with Waves to be checked/displayed								
//				tableName:		String name for the table to be created
// Output:	folder tree down to NewFolderName


FUNCTION MPaux_ShowWavesAsTable(WaveName_list,tableName)

String WaveName_list
String Tablename


SVAR AbortStr=root:App:AbortStr


// redo table
Killwindow/Z $TableName

Edit /K=1/W=(1000,0,1350,400)/N=$Tablename

Variable ww
// loop through wave list
FOR (ww=0;ww<itemsinlist(WaveName_list);ww+=1)
	
	String WaveName_Str=Stringfromlist(ww,WaveName_list)
	
	// check if wave exists
	IF (!Waveexists($Wavename_Str))
		AbortStr="MPaux_ShowWavesAsTable()\r\rWave '"+ Wavename_Str+"' does not exist.\rCheck input field"
		Killwindow/Z $Tablename
		MPaux_abort(abortStr)
	ENDIF
	
	// display wave in table
	appendtoTable $Wavename_Str

ENDFOR

END

//======================================================================================
//======================================================================================

// Purpose:	check if removeIons_IDX wave agrees with exactMZ wave in first entry in Explist
//				
// Input:		removeIonsIDX_str:	String name of wave with 1/0 for removing ions during makeCombi() operation							
//				ExpList_str:			String name of text Wave with list of samples in combined data set
//				MZname:				Sring name of Wave with exact Ion mass data	
// Output:	folder tree down to NewFolderName

FUNCTION MPaux_check_removeIonsIDXWave(removeIonsIDX_str,ExpList_str,MZname)

String removeIonsIDX_str
String ExpList_str
String MZname

SVAR abortStr=root:app:abortStr
Wave/T ExpList=$explist_str

// check if waves exist
String listofWaves=removeIonsIDX_str+";root:"+ExpList[0]+":"+MZName
Variable check=MPaux_CHeckWavesfromlist(listOfWaves)

Wave/Z nonExistIdx
KillWaves/Z NonExistIdx

IF (check!=1)// something missing
	abortStr="MPaux_check_removeIonsIDXWave():\r\rone of these Waves is missing:\r\r"+listOfWaves
	MPaux_abort(abortStr)
ENDIF

// check if wavelength is ok
String folderPath="root:"+ExpList[0]+":"
folderPath=replaceString("root:root",folderPath,"root")
	
Wave MZwave=$(folderPath+MZname)
Wave removeIonsIDX=$removeIonsIDX_str

IF (numpnts(removeIonsIDX)!=numpnts(MZwave))
	abortStr="MPaux_check_removeIonsIDXWave():\r\rwave length does not agree for:\r\r"+removeIonsIDX_str+"\r"+folderPath+MZname
	abortStr+="\r\rReset removeIon_IDX wave (YES) or abort (NO)?"
	DoAlert 1,abortStr

	IF (V_flag==0)	//cancel
		abort
	ELSE
		// make new wave and reset to 0
		Make/D/O/N=(numpnts(MZwave)) $removeIonsIDX_str
		Wave removeIonsIDX=$removeIonsIDX_str
		removeIonsIDX=0		
	ENDIF
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	get the idx of an ion identified with an ion label in the FiT-PET panel
//				
// Input:		ionLabel:	Wave with ion labels
//				info from FiT-PET panel variables
// Output:	ionIDX:	index of ion selected with the ion label variable in the FiT-PET panel


FUNCTION MPaux_getIonIDX(ionLabel)

Wave/T ionLabel

// get global info
Wave radioValues_removeIOns=root:app:radioValues_removeIOns
NVAR removeions_IDX_Var=root:app:removeions_IDX_Var
SVAR removeions_IDX_label=root:app:removeIons_label_Str

SVAR abortStr=root:app:abortStr

Variable ionIDX=-1

// get ion ID
IF (radioValues_removeIOns[0]==1)
	// idx selected
	ionIDX=removeions_IDX_Var
ELSE
	// label selected
	// find label in wave
	Grep/Q/INDX/E=("(?i)"+removeions_IDX_label) ionLabel
	// no ion found
	IF (V_value<1)
		abortStr="MPaux_getIonIDX():\r\rno ion found with label:\r\r"+removeions_IDX_label
		MPaux_abort(abortStr)
	ENDIF
	//more than one found
	IF (V_value>1)
		abortStr="MPaux_getIonIDX():\r\rmultiple entries found for:\r\r"+removeions_IDX_label + "\r\rin wave:\r\r"+getwavesDataFolder(ionLabel,2)
		MPaux_abort(abortStr)
	ENDIF
	
	//only one found
	Wave W_Index
	ionIDX=W_Index[0]
	
	Killwaves/Z W_index	// clean up
	
ENDIF

RETURN ionIdx

END
//======================================================================================
//======================================================================================

// Purpose:	calculate C,H,O, N,S,Si, I,F,Cl numbers from label Wave
//				entries with "unknown" will be ignored

// Input:		ionLabels:	txt waves with ionLabels (=sum formulas)
//
// Output:	ElementNum:	2D wave with all element numbers (in currentdatafolder)
//

Function MPaux_calcElementFromLabel(ionLabels_in)

Wave/T ionLabels_in

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// check that input wave exists
IF (!Waveexists(ionLabels_in))
	abortStr= "MPaux_calcElementFromLabel():\r\rpassed ion label wave does not exist -> check input"
	ABort
ENDIF

// check for format (PTR viewer output is C[12]1H[1]1)
duplicate/T/FREE ionLabels_in,ionLabels_clean
//Wave/T ionLabels_clean

// check for [ -> could bePTRviewer data with 
Grep /INDX/Q/E=("\\[") ionLabels_clean

IF (V_value>0)
	// handle standard isotope
	ionLabels_clean=replacestring("C[12]",ionLabels_clean,"C")
	ionLabels_clean=replacestring("H[1]",ionLabels_clean,"H")
	ionLabels_clean=replacestring("O[16]",ionLabels_clean,"O")
	ionLabels_clean=replacestring("N[14]",ionLabels_clean,"N")
	ionLabels_clean=replacestring("S[32]",ionLabels_clean,"S")
	ionLabels_clean=replacestring("Si[28]",ionLabels_clean,"Si")
	ionLabels_clean=replacestring("I[126]",ionLabels_clean,"I")
	ionLabels_clean=replacestring("F[19]",ionLabels_clean,"F")
	ionLabels_clean=replacestring("Cl[35]",ionLabels_clean,"Cl")
	ionLabels_clean=replacestring("Br[79]",ionLabels_clean,"Br")
	
	// handle mionr isotop
	ionLabels_clean=replacestring("C[13]",ionLabels_clean,"[13C]")
	ionLabels_clean=replacestring("O[18]",ionLabels_clean,"[18O]")
	ionLabels_clean=replacestring("O[17]",ionLabels_clean,"[17O]")
	ionLabels_clean=replacestring("N[15]",ionLabels_clean,"[15N]")
	ionLabels_clean=replacestring("S[33]",ionLabels_clean,"[33S]")
	ionLabels_clean=replacestring("S[34]",ionLabels_clean,"[34S]")
	ionLabels_clean=replacestring("Si[29]",ionLabels_clean,"[29Si]")
	ionLabels_clean=replacestring("Si[30]",ionLabels_clean,"[30Si]")
	
	ionLabels_clean=replacestring("Cl[37]",ionLabels_clean,"[37Cl]")
	ionLabels_clean=replacestring("Br[81]",ionLabels_clean,"[81Br]")

ENDIF

// container for numeric elemental composition
make/O/I /N=(numpnts(ionLabels_clean),10) ElementNum=0
Note elementNum,"elemental composition from ion labels\rC;H;O;N;S;Si;I;F;Cl;Br;"

// set dimension labels
SetDimLabel 1,0,C,ElementNum
SetDimLabel 1,1,H,ElementNum
SetDimLabel 1,2,O,ElementNum
SetDimLabel 1,3,N,ElementNum
SetDimLabel 1,4,S,ElementNum
SetDimLabel 1,5,Si,ElementNum
SetDimLabel 1,6,I,ElementNum
SetDimLabel 1,7,F,ElementNum
SetDimLabel 1,8,Cl,ElementNum
SetDimLabel 1,9,Br,ElementNum

// container for full info (as text)
//Make/O/T/N=(numpnts(ionLabels_clean)) ionLabel_info

Variable ii=0,ff=0

String Elements="C;H;O;N;S;Si;I;F;Cl;Br;"

// convert ion labels to string list of keys
Duplicate/O/T ionLabels_clean,IonLabels_list
//IonLabels_list=MPaux_formula2List(ionLabels_clean)	// note sure why I am doing this? Probably to capture Elements which are not in ElementNum?

	
// loop through ion labels
FOR (ii=0;ii<numpnts(ionLabels_clean);ii+=1)	// step through list of ion labels
	String formStr=ionLabels_clean[ii]
//-----------
	// look for upper case characters, optionally followed by lower case characters
	Variable len, i, nFound, currCharNum, bracketPos, nElem, nIso, elemNum
	String currChar, elemName, isoName, elemList, isoList, numStr, elemNumList, isoNumList
	len = strLen(formStr)
	Make/N=(len)/FREE startPos, stopPos
	Make/N=(len)/FREE/T elemNameWv, isoNameWv // make sure it's long enough to avoid need for redimensioning in loop
	
	startPos = NaN
	stopPos = NaN
	elemNameWv = ""
	isoNameWv = ""
	nFound = 0
	bracketPos = -1
	elemList = ""
	elemNumList = ""
	isoList = ""
	isoNumList = ""
	
	For (i=0;i<len;i+=1)	// step through each element of the label to find start positions
		
		currChar = formStr[i]
		currCharNum = char2Num(currChar)
		if (currCharNum==91) // open bracket [
			bracketPos = i
		endif
		if (currCharNum>64 && currCharNum<91) // upper case "A"=65, "Z"=90, "a"=97, "z"=122
			startPos[nFound] = i
			elemName = currChar
			
			currCharNum = char2Num(formStr[i+1])
			if (currCharNum>96 && currCharNum<123) // check for lower case character immediately following upper case char
				stopPos[nFound] = i+1
				elemName += formStr[i+1]
			else
				stopPos[nFound] = i
			endif
			if (WhichListItem(elemName,elemList)<0)
				elemList += elemName + ";"
				elemNumList += elemName + ":0;"
				nElem += 1
			endif
			elemNameWv[nFound] = elemName
			if (bracketPos>-1)
				if (char2Num(formStr[stopPos[nFound]+1]) != 93) // not closing bracket, formula is invalid
					print "MPaux_formula2List(): invalid formula: "+formStr
					Break
				endif
				isoName = formStr[bracketPos,stopPos[nFound]+1]
				startPos[nFound] = bracketPos
				stopPos[nFound] += 1 // account for closing bracket
				if (WhichListItem(isoName,isoList)<0)
					isoList += isoName + ";"
					isoNumList += isoName + ":0;"
					nIso += 1
				endif
				isoNameWv[nFound] = isoName
				bracketPos = -1
			endif
			nFound +=1
		endif
		
	EndFor
	
	Redimension/N=(nFound+1) startPos, stopPos, elemNameWv
	startPos[nFound] = len-1 // set last start position to end of string to make number counting easier
	
	// get the numbers for each found element
	For (i=0;i<nFound;i+=1)
		elemName = elemNameWv[i]
		isoName = isoNameWv[i]
		if (startPos[i+1]>stopPos[i])
			numStr = formStr[stopPos[i]+1,startPos[i+1]]
			elemNum = str2Num(numStr)
			if (numtype(elemNum)) // can happen if isotopes are present
				elemNum = 1
			endif
		else
			elemNum = 1
		endif
		
		// store in numeric wave
		Variable ElementIdx=WhichListItem(elemName,Elements)
		IF (ElementIdx>=0)	// catch unknown element
			ElementNum[ii][ElementIdx]+=elemNum
		ENDIF
		
		// store for IonLabels_list
		elemNumList = ReplaceNumberByKey(elemName,elemNumList,elemNum+NumberByKey(elemName,elemNumList))
		if (StrLen(isoName))
			isoNumList = ReplaceNumberByKey(isoName,isoNumList,elemNum+NumberByKey(isoName,isoNumList))
		endif
	EndFor
	
	// sort lists
	elemList = ReplaceString(";",SortList(elemList),",")
	elemNumList = ReplaceString(";",SortList(elemNumList),",")
	isoList = ReplaceString(";",SortList(isoList),",")
	isoNumList = ReplaceString(";",SortList(isoNumList),",")

	IonLabels_list[ii]="ElemList:"+elemList+";IsoList:"+isoList+";ElemNumList:"+elemNumList+";IsoNumList:"+isoNumList
		
ENDFOR	// ion label loop

END

//======================================================================================
//======================================================================================
// Purpose:	convert ion labels which may contain isotopes and other complicated stuff to "simple" 
//				adapted from HS_Form2List() from Harald Stark
//
// Input:		formStr: string containing sum formula
//
// Output:	string with info from ion label put into "key word" list
//					

Function/S MPaux_formula2List(formStr)
String formStr
Wave startPos, stopPos // start and stop positions for elements
Wave/T elemNameWv

	// look for upper case characters, optionally followed by lower case characters
	Variable len, i, nFound, currCharNum, bracketPos, nElem, nIso, elemNum
	String currChar, elemName, isoName, elemList, isoList, numStr, elemNumList, isoNumList
	len = strLen(formStr)
	Make/N=(len)/FREE startPos, stopPos
	Make/N=(len)/FREE/T elemNameWv, isoNameWv // make sure it's long enough to avoid need for redimensioning in loop
	
	startPos = NaN
	stopPos = NaN
	elemNameWv = ""
	isoNameWv = ""
	nFound = 0
	bracketPos = -1
	elemList = ""
	elemNumList = ""
	isoList = ""
	isoNumList = ""
	
	For (i=0;i<len;i+=1)
		
		currChar = formStr[i]
		currCharNum = char2Num(currChar)
		if (currCharNum==91) // open bracket [
			bracketPos = i
		endif
		if (currCharNum>64 && currCharNum<91) // upper case "A"=65, "Z"=90, "a"=97, "z"=122
			startPos[nFound] = i
			elemName = currChar
			
			currCharNum = char2Num(formStr[i+1])
			if (currCharNum>96 && currCharNum<123) // check for lower case character immediately following upper case char
				stopPos[nFound] = i+1
				elemName += formStr[i+1]
			else
				stopPos[nFound] = i
			endif
			if (WhichListItem(elemName,elemList)<0)
				elemList += elemName + ";"
				elemNumList += elemName + ":0;"
				nElem += 1
			endif
			elemNameWv[nFound] = elemName
			if (bracketPos>-1)
				if (char2Num(formStr[stopPos[nFound]+1]) != 93) // not closing bracket, formula is invalid
					print "MPaux_formula2List(): invalid formula: "+formStr
					return ""
				endif
				isoName = formStr[bracketPos,stopPos[nFound]+1]
				startPos[nFound] = bracketPos
				stopPos[nFound] += 1 // account for closing bracket
				if (WhichListItem(isoName,isoList)<0)
					isoList += isoName + ";"
					isoNumList += isoName + ":0;"
					nIso += 1
				endif
				isoNameWv[nFound] = isoName
				bracketPos = -1
			endif
			nFound +=1
		endif
	EndFor
	
	Redimension/N=(nFound+1) startPos, stopPos, elemNameWv
	startPos[nFound] = len-1 // set last start position to end of string to make number counting easier
	
	For (i=0;i<nFound;i+=1)
		elemName = elemNameWv[i]
		isoName = isoNameWv[i]
		if (startPos[i+1]>stopPos[i])
			numStr = formStr[stopPos[i]+1,startPos[i+1]]
			elemNum = str2Num(numStr)
			if (numtype(elemNum)) // can happen if isotopes are present
				elemNum = 1
			endif
		else
			elemNum = 1
		endif
		elemNumList = ReplaceNumberByKey(elemName,elemNumList,elemNum+NumberByKey(elemName,elemNumList))
		if (StrLen(isoName))
			isoNumList = ReplaceNumberByKey(isoName,isoNumList,elemNum+NumberByKey(isoName,isoNumList))
		endif
	EndFor
	
	// sort lists
	elemList = ReplaceString(";",SortList(elemList),",")
	elemNumList = ReplaceString(";",SortList(elemNumList),",")
	isoList = ReplaceString(";",SortList(isoList),",")
	isoNumList = ReplaceString(";",SortList(isoNumList),",")

	Return "ElemList:"+elemList+";IsoList:"+isoList+";ElemNumList:"+elemNumList+";IsoNumList:"+isoNumList

End

//======================================================================================
//======================================================================================
// Purpose:		remove iodide contribution from CIMS ion masses 
// Input:			MZmass:			exact mass of ions (including iodide)
//					MZlabels: 		text wave with ion labels 
//
// Output:		MZmass_noi:		exact MZ of neutral ions (in current datafolder)
//					MZlabels_noi:	ion labels of neutral ions (in current datafolder)		

Function MPaux_removeIodide(MZmass,MZlabels)

Wave MZmass
Wave/T MZlabels

// create result waves
String NewMZname=NameOfWave(MZmass)+"_noi"
String newlabelName=NameOfWave(MZlabels)+"_noi"

Duplicate/O MZmass,$newMZname
Duplicate/O/T MZlabels,$newLabelName

Wave newMZ=$newMZname
Wave/T NewLabel=$newLabelName

String CurrentFOlder=getwavesDataFolder(MZlabels,1)

// look for ElementNum wave
IF (!Waveexists($(CurrentFolder+":ElementNum")))
	// calculate element numbers from labels
	MPaux_calcElementFromlabel(MZlabels)
	Wave ElementNum
ELSE
	Wave ElementNum=$(CurrentFolder+":ElementNum")
ENDIF

Variable Iidx=FindDimlabel(ElementNum,1,"I")
Variable Hidx=FindDimlabel(ElementNum,1,"H")

// loop through ion labels
Variable ii=0,ff=0,ct=0

FOR (ii=0;ii<numpnts(MZmass);ii+=1)
	String labelStr=MZlabels[ii]
	
	IF (ElementNum[ii][Iidx]==1)	// 1 iodide
		IF (StringMatch("*I1*",labelStr))
			NewLabel[ii]=ReplaceString("I1",labelStr,"")	// remove "I1"
		ELSE
			NewLabel[ii]=ReplaceString("I",labelStr,"")	// remove "I"
		ENDIF	
	ELSEIF (ElementNum[ii][Iidx]>1)	// more than 1 iodide
		NewLabel[ii]=ReplaceString(("I"+num2str(ElementNum[ii][Iidx])),labelStr,"")
	ELSE	
		// 0 iodide (declustered ions mostly in PECK16 data)
		// increase H by 1
		String HStr="H"+num2Str(ElementNum[ii][Hidx])
		String newHStr="H"+num2Str(ElementNum[ii][Hidx]+1)
		NewLabel[ii]=ReplaceString(Hstr,labelStr,NewHstr)
		//ElementNum[ii][Hidx] = ElementNum[ii][Hidx]+1
		Ct+=1
	ENDIF

ENDFOR

NewLabel=replaceString("-", NewLabel,"")
NewLabel=replaceString(" ", NewLabel,"")
Note NewLabel,"CHOI ions -I, CHO ions +H"

IF (ct>0) // at least one case with Inum==0
	Note ElementNum, "Hnum was increased by 1 for CHO ions"
ENDIF

// change exact mass: remove iodid mass or add 1H
newMZ = ElementNum[p][Iidx]==0 ? mzMass[p]+1.008 : mzMass[p] - ElementNum[p][Iidx]*126.90447
Note newMZ,"CHOI ions -I, CHO ions +H"

END


//======================================================================================
//======================================================================================

// OBSOLETE

// Purpose:		load data for PMF analysis from txt files created e.g. from MATLAB dataprocessing
//					one file for each wave type
//					all files can be loaded at once or subset of files
// Input:			select txt files with preprocessed data through dialog
//					input files with multiple columns MUST have tab  as delimiter!
//					time series:	one column with X time in Igor format
//					peak labels:	one column with X peak labels (C1 H1 O1, C1 H2 O1,...)
//					masses:		one column with Y exact ion masses (42.001, 42.05,...)
//					mass spectra: matrix with X by Y entries with mass spectra data (signal)
// Output:		waves ready to be used in PMF toolkit
//					waves will be sorted into subfolder and named according to type (with new data set user must check for correct label for MSdata and MSerror)
// called by:	standalone -> obsolete !

FUNCTION MPaux_dataFromtxtloader()

// get abortStr for reporting
SVAR abortStr=root:app:abortStr
IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// get LoadFolder_Str for storing location of loaded data
SVAR loadFolder_Str=root:APP:loadFolder_Str
IF (!SVAR_exists(loadFolder_Str))
	String/G loadFolder_Str=""
ENDIF

//-----------------------------------------------------
// get input from user: select txt files and name for subfolder

Variable refNum
String message = "Select txt files to import"
String outputPath
String fileFilters = "Data Files (*.txt):.txt;"
fileFilters += "All Files:.*;"

Open /D /R /F=fileFilters /M=message/MULT=1 refNum	// open file selection dialog
String fileList = S_fileName	

//user clicked cancel (empty list)
IF (stringMatch(fileList,""))
	abort
ENDIF

// change delimiter in string list to ;
fileList=replaceString("\r",fileList,";")		//String list of file names: "file0;file1;..."

// get name for subfolder (simple input dialog)
String subName="PMFinput"
Prompt subName, "Sub Folder Name:"
DoPrompt "Select name", subName

//user clicked cancel
IF (V_FLAG)
	Abort
ENDIF

// check folderName for subfolder levels and length
String subname4Test=replaceString("root:",subname,"")
IF (Itemsinlist(subname4Test,":")>1)
	String alertStr="MPaux_dataFromtxtloader():\r\rPET data prep panel cannot tolerate multiple subfolder levels."
	alertStr+="\r"+subName
	alertStr+="\rContinue (YES) with this folder name? \rAbort (NO) if you need full compatibility with PET for data preparation."
	Doalert 1,alertStr
	IF (V_flag==2)
		MPaux_abort(alertStr)
	ENDIF
ENDIF

String NewsubName=MPaux_folderName("root:",subName4Test,"combi_")
IF (!Stringmatch(NewsubName,subName))
	abortStr="MPaux_dataFromtxtloader():\r\rChosen Combi folder name is too long. Select a different Name to avoid further issues."
	abortStr+="\r"+subname4Test+": "+num2str(strlen(subname4Test))+" bytes"
	MPaux_abort(abortStr)
ENDIF

// check that it is legal
IF(!stringmatch(cleanupName(subname4Test,0),subname4Test))
	abortStr="MPaux_dataFromtxtloader():\r\rName of data folder is illegal. Avoid special characters and start the name with a letter."
	abortSTr+="\r"+subname
	MPaux_abort(abortSTr)
ENDIF

// go to/create data folder picked by user
String FullDFpath="root:"+subName

NewDatafolder/O/S $(FullDFpath)	// the $ sign is needed otherwise the new folder would be called "fullDFpath"
LoadFolder_Str=FullDFpath	// store for later

// check if Fit_PET panel info is available -> use chosen Wavenames
IF (Waveexists(root:APP:DataWaveNames))
	Wave/T Wavenames=root:APP:DataWaveNames
ELSE
	Make/T/FREE/N=(5) Wavenames = {"MSdata","","ExactMZ","IonLabel","Tdesorp"}
ENDIF

print "------------------"
print date() + " " + time() + " load data from text files"
print "If files contain multiple scans, use the following command to get the idxSample values needed for next step."
print "MPaux_makeIDXsample(\"root:APP:IDXsample\",root:"+subname+":"+Wavenames[%Tname]+")"

//-----------------------------------------------------
// loop through files on list and load them

Variable ff,ii
String Firstline="",FileName=""
String TempName=""	// stores name for wave
Variable TwoD=0		// 0: 1D wave, 1: matrix
Variable FileTypeTest=0	// check if file type could be determined
Variable k_set = 0	// set auto detection for LoadWave

FOR (ff=0;ff<Itemsinlist(fileList);ff+=1)	//go from 0 to number of selected files
	// get first values in files and assign label for data type
	// 1		mass spectra: multiple entries (large values)
	// 4		exact masses:	first entry > 39amu
	// 8		temperature:		first entry > 10C and <39C
	// 16		labels:		 	text without ':'
	// 32		tseries:			first entry > 3.0e9 (Igor format assumed)
	// 64		tseries_txt		text with ':'
	
	// get current filename
	FileName=Stringfromlist(ff,fileList)
	
	// get first line of file to check type
	open/R refnum as filename
	Freadline refNum, FirstLine	// reads first line
	Freadline refNum, FirstLine	// reads next to avoid issue if first row has labels
	close refnum
	
	//more  than one entry? (expects tab (\t) separated)
	IF (Itemsinlist(FirstLine, "\t") > 1)
		// 2D waves
		TwoD=1
			
		// data
		TempName=WaveNames[0]
		Filetypetest=1
		
	ELSE
		// 1D wave
		twoD=0
		Variable testNum=str2num(Stringfromlist(0,Firstline,"\t"))	// first element
		
		IF (itemsinlist(Firstline,":")>1)	// catch time series as string (will have hh:mm:ss)
			tempName="t_series_txt" 
			filetypetest=64
			k_set=2			// force to read as text (to avoid issue with american date format)
		ELSEIF (numtype(testNum)==2)		//text gives NaN with str2num comand
			// ion labels
			tempName=wavenames[3]
			filetypeTest=16
		ELSE
			// temperature
			IF (testNum<39 && testnum>10)	// first temperature between 10 and 35C
				tempName=wavenames[4] 
				filetypetest=8
			ENDIF
			// ion mass
			IF (testNum>39 && testNum<3e9)	// first mass should be larger than 40amu
				tempName=wavenames[2] 
				filetypetest=4
			ENDIF	
			
			IF (testNum>3e9)	// time series in Igor format
				tempName="t_series" 
				filetypetest=32
			ENDIF	
		ENDIF
	ENDIF // end of file content test
	
	// if type could not be identified -> notify user
	IF (filetypetest==0)
		print "unable to determine file content type\rloading content with generic name WaveX"
	ENDIF
	
	// do the loading with defined parameters
	IF (twoD==1)
		// 1D files
		IF (filetypetest>0)
			loadwave/O/A/B=("N="+tempName+";")/Q/D/J/k=(k_set)/M filename
		ELSE
			loadwave/O/A/Q/D/J/k=(k_set)/M filename
		ENDIF
	ELSE
		// 2D files (=more than 1 column per file)
		IF (filetypetest>0)
			loadwave/O/A/B=("N="+tempName+";")/Q/D/J/k=(k_set) filename
		ELSE
			loadwave/O/A/Q/D/J/k=(k_set) filename
		ENDIF
	ENDIF
	
	// convert time string to number assuming dd.mm.yyyy hh:mm:ss format
	IF (filetypetest==64)
		Wave/T t_series_txt
		Make/D/O/N=(numpnts(t_series_txt)) t_series
		
		t_series=MPaux_string2js(t_series_txt,"dd.mm.yyyy hh:mm:ss")
		Killwaves/Z t_series_txt
		
		IF (numtype(t_series [1])==2)	// notify if problem
			print "problem with converting txt time values to numbers for wave: "+filename
			print "check the date/time format and use string2js(t_series_txt,\"yourFormatString\") manually"
		ENDIF
		
	ENDIF
	
	// set format of time series wave
	Wave t_series
	IF (filetypetest==32 || filetypetest==64)
		setscale d,0,0, "dat", t_series
	ENDIF
	
	//reset file type test value
	FileTypeTest=0
	
ENDFOR	// end of file loop

//-----------------------------------------------------

// clean up
Killwaves/Z tempWave,Testwave

END


//======================================================================================
//======================================================================================

// Purpose:		create list of solution folders in root:PMFresults for exporting to text files
// Input:			
// Output:		FolderList:	String with folder list which is used in PopUp menu
// called by:	popupmenu 'Pop_Solution4Export'

FUNCTION/S MPaux_popmenu_List()

String FOlderList=""

Variable nof=countObjects("root:PMFResults",4)
Variable ff

FOR (ff=0;ff<nof;ff+=1)
	FOlderList+=getindexedObjName("root:PMFResults",4,ff)+";"
ENDFOR

RETURN FolderList 

END

//======================================================================================
//======================================================================================

// purpose:	transfer the PMF parameters from MasPET folder to the PET variables
// 				this does not contain wavenames!!!
// 				!!! all other global parameters are either default or whatever was set in PET !!!
// 				for future: if more globals are needed -> add to list and set them manually
//
// INput:		sourcefolder:	folder from which to copy the parameters
//				targetFOlder:	change values in this folder
//				sourceList:		list of variables in xource folder
//				TargetList		corresponding list of variables in target folder
//
// Output:	transfers some settings/parameters for the PMF calcualtions from the Source folder to the Target folder
//				previous values in TargetFolder are overwritten

// called by: runPMF button, openPETresults

FUNCTION MPaux_transferPMFparams(SourceFolder,SourceList,Targetfolder,TArgetlist)

String SourceFolder		// folder containing parameters to be copied
String SourceList		// names of parameters to be copied
String Targetfolder		// folder the values will be copied to
String TArgetlist		// names of the parameters in that folder

SVAR abortStr= root:APP:abortStr


// loop through list and set values
Variable ii

FOR (ii=0;ii<Itemsinlist(TArgetlist);ii+=1)

	String Current_Target=Stringfromlist(ii,Targetlist)
	String current_source=Stringfromlist(ii,SourceList)
	
	// check VAR of STR
	IF(stringmatch(Current_source,"*_VAR"))
		// numeric
		// get variables
		NVAR NVAR_source=$("root:"+sourceFOlder+":"+current_source)
		NVAR NVAR_Target=$("root:"+Targetfolder+":"+current_Target)
		
		// check if both variables exist
		IF (!NVAR_Exists(NVAR_source)) 
			abortStr="MPaux_transferPMFparams():\r\rglobal variable root:APP:"+current_source+" does not exist => aborting"
			MPaux_abort(AbortStr)
		ENDIF
		
		IF  (!NVAR_Exists(NVAR_Target))
			abortStr="MPaux_transferPMFparams():\r\rglobal variable root:pmf_calc_globals:"+current_Target+" does not exist => aborting"
			MPaux_abort(AbortStr)
		ENDIF
		
		// set value
		NVAR_Target=NVAR_source		
	ELSE
		// string
		// get variables
		SVAR SVAR_source=$("root:APP:"+current_source)
		SVAR SVAR_Target=$("root:"+Targetfolder+":"+current_Target)
		
		// check if both variables exist
		IF (!SVAR_Exists(SVAR_source)) 
			abortStr="MPaux_transferPMFparams():\r\rglobal variable root:"+SourceFolder+":"+current_source+" does not exist => aborting"
			MPaux_abort(AbortStr)
		ENDIF
		
		IF  (!SVAR_Exists(SVAR_Target))
			abortStr="MPaux_transferPMFparams():\r\rglobal variable root:"+Targetfolder+":"+current_Target+" does not exist => aborting"
			MPaux_abort(AbortStr)
		ENDIF

		// set value
		SVAR_Target=SVAR_source		

	ENDIF

ENDFOR

//---------------------
// Igor folders
svar pmfDFNm = $("root:"+Targetfolder+":pmfDFNm")
SVAR combiName_Str=root:APP:combiName_str
pmfDFNm=combiName_Str+":"
pmfDFnm=replacestring("::",pmfDFNm,":")	// fix issue with possibly missing ":"

// wavenames
svar DataMxNm = $("root:"+TargetFOlder+":DataMxNm")
svar StdDevMxNm = $("root:"+TargetFOlder+":StdDevMxNm")
svar ColDescrWvNm = $("root:"+TargetFOlder+":ColDescrWvNm")
svar ColDescrTxtWvNm = $("root:"+TargetFOlder+":ColDescrTxtWvNm")
svar ColDesTxtWvNm = $("root:"+TargetFOlder+":ColDesTxtWvNm")	// added for PET >3.07
svar RowDescrWvNm = $("root:"+TargetFOlder+":RowDescrWvNm")

Wave/T Wavenames=root:APP:datawavenames

DataMxNm=wavenames[%MSdataName]
StdDevMxNm=wavenames[%MSerrName]
ColDescrWvNm=wavenames[%MZname]
ColDescrTxtWvNm=wavenames[%LabelName]
ColDesTxtWvNm=wavenames[%LAbelName]
RowDescrWvNm=wavenames[%Tname]

END

//======================================================================================
//======================================================================================

// Function working just like pmfCalcs_butt_RunPMF() but without pulling info from PET GUI

// purpose:		start the PMF calculations with external exe
//					use parmaeters from Mas_PET panel and the hard coded values
//				
// input:			parameters and waves selected in Panel
// output:		PMF results
// called by:	MPbut_Step2_button_control() -> but_runPMF

FUNCTION MPaux_RUN_PMF()

SVAR abortStr=root:APP:abortStr

// THIS IS FROM pmfCalcs_butt_RunPMF()

// 3.00C  Changed this sanity check to happen right away.
pmfCalcs_DoesExeExist()

// new in version 2.02 check for a bad ini file for early adopters
pmfCalcs_checkIniFile()

close/a  // Just in case the last time PMF ran it crashed and some files were left open

//imu2.06 make sure we save names of all waves
//pmfCalcs_saveWvNms_runTab()	// this would pull wavenames from PET Panel -> we do not want that!

svar pmfDFNm = root:pmf_Calc_globals:pmfDFNm
svar DataMxNm = root:pmf_Calc_globals:DataMxNm
svar StdDevMxNm = root:pmf_Calc_globals:StdDevMxNm
	
nvar p_min = root:pmf_Calc_globals:p_min
nvar p_max = root:pmf_Calc_globals:p_max

nvar exploreOrBootstrap = root:pmf_Calc_globals:exploreOrBootstrap	// 2.00A
nvar SeedOrFpeak = root:pmf_Calc_globals:SeedOrFpeak		// 1.3I		// 0 means fpeak, 1 means seed

nvar fpeak_method= root:pmf_Calc_globals:fpeak_method
nvar fpeak_min = root:pmf_Calc_globals:fpeak_min
nvar fpeak_max = root:pmf_Calc_globals:fpeak_max
nvar fpeak_delta = root:pmf_Calc_globals:fpeak_delta
svar fpeak_methodStr = root:pmf_Calc_globals:fpeak_methodStr

nvar saveExpAfterPMF = root:pmf_Calc_globals:saveExpAfterPMF

nvar pmfModelError = root:pmf_Calc_globals:pmfModelError  //1.04F		// this is the variable in the panel


variable filenum, tempVar1, tempVar2
string tempStr

// start of sanity checks.  Sanitize user inputs
// Step 1.  Verify the path to the PMF executable
Pathinfo $PMF_EXE_IGOR_PATH_NAME
if (V_flag==0)
	abort "You must choose a path for the pmf executable file. - aborting from RUN_PMF_APP "
endif
	
// Step 2. Do the Matrix choices make sense?
// always get the latest value from the panel
wave DataMx = $pmfDFNm+DataMxNm
wave StdDevMx = $pmfDFNm+StdDevMxNm

if (strlen(DataMxNm) == 0 || strlen(StdDevMxNm) == 0)
	Abort "You must select the data and error wave. - aborting from RUN_PMF_APP"
endif

tempStr =selectString(SeedOrFpeak, " fPeaks", "seeds")		// 0 is fPeak, 1 is seed

if (strlen(pmfDFNm) == 0 )		// DTS 3.00C
	pmfDFNm="root:" 
endif
	
//check that data and error matrices have the same dimensions
if (dimsize(DataMx, 0) == dimsize(StdDevMx,0) && dimsize(DataMx, 1) == dimsize(StdDevMx, 1))
	printf "// Proceeding with analysis of data and error matrices with %d rows and %d columns %s.\r", dimsize(DataMx,0), dimsize(DataMx,1),  " varying the "+tempStr
else
	printf "// Cannot proceed with analysis -- matrices do not have the same dimensions.\r"
	printf "// 	dataMx has %d rows and %d columns,\r", dimsize(DataMx, 0), dimsize(DataMx, 1)
	printf "// 	  StdDevMx has %d rows and %d columns.\r", dimsize(StdDevMx,0), dimsize(StdDevMx,1)
	abort "Cannot proceed with analysis -- matrices do not have the same dimensions. - Aborting from pmfCalcs_butt_RunPMF"
endif

// check for nans, infs in data and error matrix
wavestats/q/m=1 DataMx	
variable/c comp
if (V_numNans>0)		// 3.05B
	comp=FindNaNValue2D(DataMx)
	DoWindow/k noNanDataMatrix
	Edit/N=noNanDataMatrix DataMx as "noNanDataMatrix"
	MOdifyTable/w=noNanDataMatrix selection=(real(comp) , imag(comp), real(comp) , imag(comp), real(comp) ,imag(comp))
	printf "Cannot continue -- "+ num2istr(V_numNans)+" nans found in the data matrix.\r"
	abort "Found "+ num2istr(V_numNans)+" NaNs in the data matrix "+NameofWave(dataMx) +" Aborting from pmfCalcs_butt_RunPMF"
elseif(V_numINFs>0)
	comp=FindNaNValue2D(DataMx, infFlag=1)
	DoWindow/k noNanDataMatrix
	Edit/N=noNanDataMatrix DataMx as "noNanDataMatrix"
	MOdifyTable/w=noNanDataMatrix selection=(real(comp) , imag(comp), real(comp) , imag(comp), real(comp) ,imag(comp))
	printf "Cannot continue -- "+ num2istr(V_numINFs)+" infs found in the data matrix.\r"
	abort "Found "+ num2istr(V_numINFs)+" Infs in the data matrix "+NameofWave(dataMx) +" Aborting from pmfCalcs_butt_RunPMF"
endif

wavestats/q/m=1 StdDevMx	
if (V_numNans>0)
	comp=FindNaNValue2D(StdDevMx)
	DoWindow/k noNanStdDevMx
	Edit/N=noNanStdDevMx StdDevMx as "noNanStdDevMx"
	MOdifyTable/w=noNanStdDevMx selection=(real(comp) , imag(comp), real(comp) , imag(comp), real(comp) ,imag(comp))
	printf "Cannot continue -- "+ num2istr(V_numNans)+" nans found in the error matrix.\r"
	abort "Found "+ num2istr(V_numNans)+" NaNs in the error matrix "+NameofWave(dataMx) +" Aborting from pmfCalcs_butt_RunPMF"
elseif(V_numINFs>0)
	comp=FindNaNValue2D(StdDevMx, infFlag=1)
	DoWindow/k noNanDataMatrix
	Edit/N=noNanDataMatrix StdDevMx as "noNanStdDevMx"
	MOdifyTable/w=noNanDataMatrix selection=(real(comp) , imag(comp), real(comp) , imag(comp), real(comp) ,imag(comp))
	printf "Cannot continue -- "+ num2istr(V_numINFs)+" infs found in the data matrix.\r"
	abort "Found "+ num2istr(V_numINFs)+" Infs in the data matrix "+NameofWave(dataMx) +" Aborting from pmfCalcs_butt_RunPMF"
endif
if (V_min<=0)  //imu2.05 zero or negative values in error matrix
	DoWindow/k noNanStdDevMx
	Edit/N=noNanStdDevMx DataMx as "noNanStdDevMx"
	MOdifyTable/w=noNanDataMatrix selection=(V_minRowLoc ,V_minColLoc, V_minRowLoc, V_minColLoc, V_minRowLoc,V_minColLoc)
	printf "Cannot continue -- zero or negative values found in the error matrix.\r"
	abort "Found zeros or negative values in the error matrix "+NameofWave(StdDevMx) +" Aborting from pmfCalcs_butt_RunPMF"
endif

// Step 3.  Check the fpeak (or seed method)
if (fpeak_method==0)	// we are using a wave; initialize global variables just in case they are used
	if (strlen(fpeak_methodStr)==0)	// user chose to vary the fpeak/see via the wave but the wave name wasn't entered
		abort "You must choose a wave with values for the fpeak or seed. - aborting from pmfCalcs_butt_RunPMF "
	endif		
	wave/z fpeak_wave = $pmfDFNm+fpeak_methodStr
	if (! WaveExists(fpeak_wave)) 		// 1.04E
		abort "Had problems with the selection of the fpeak or seed wave.  - Aborting from pmfCalcs_butt_RunPMF"
	endif
	sort fpeak_wave fpeak_wave
	wavestats/q/m=1 fpeak_wave
	tempVar1 = V_min
	if ( V_numNans>0 || V_numInfs>0 || V_npnts>50 )	// some sanity checks
		abort "Either there are some nans or infs in the seed/fpeak wave or the number of fpeak values is >50 (too many!) - Aborting from pmfCalcs_butt_RunPMF"
	endif
	if ( SeedOrFpeak==1)		// varying seeds 	//1.04E
		duplicate/o fpeak_wave temp_wave
		temp_wave = abs(fpeak_wave - round(fpeak_wave)) // get fractional values
		tempVar2 = sum(temp_wave)
		if (tempVar1<0 || tempVar2>0)
			abort "Either there are negative or fractional values in the seed wave - seeds must be integers >=0 - Aborting from pmfCalcs_butt_RunPMF"
		endif 
		killwaves temp_wave
	endif		
	fpeak_min = v_min
	fpeak_max = v_max
	fpeak_delta = 0
else 	// we are calculating all the seed values
	switch(SeedOrFpeak) //imu2.05 -- added check fro fpeak_delta=0 for fpeak
		case 0: // fpeak
			if ( fpeak_delta<0 )  //imu2.05
				abort "Fpeak values must have the delta value > 0 - Aborting from pmfCalcs_butt_RunPMF"			
			elseif( fpeak_delta == 0 && (fpeak_max- fpeak_min) != 0)  //imu2.05 will allow delta = 0 **only** if min and max are the same
				abort "Fpeak values must have the delta value > 0 - Aborting from pmfCalcs_butt_RunPMF"								
			endif
			break
		case 1: // seed
			if ((fpeak_min<0 || fpeak_delta<1 || abs(fpeak_delta - round(fpeak_delta)) >0 )  )		//1.04D change from fpeak_min<=0		//1.04E change for integer check
				abort "Seed values must be >0 and the delta value >=1 - Aborting from pmfCalcs_butt_RunPMF"
			endif
			break
		endswitch
endif

// check that low_FPEAK <= high_FPEAK, regardless if using a wave or not
if (fpeak_min > fpeak_max)
	printf "Cannot continue -- low FPEAK must be less than or equal to high FPEAK.\r"
	abort "Cannot continue -- low FPEAK must be less than or equal to high FPEAK. -  Aborting from pmfCalcs_butt_RunPMF"
endif

// Step 4. Check p (number of factors)
// check that first and last p values are integers and that first_p < last_p
if (trunc(p_min) != p_min || trunc(p_max) != p_max)  
	// at least one value is not an integer
	printf "Cannot continue -- p values must be integers.\r"
	abort "Cannot continue -- p values must be integers. - Aborting from pmf_runPMF_range_p_fpeak"
endif	
// check for a negative factor or  first > last
if (! (0 < p_min && p_min <= p_max) )
	printf "Cannot continue -- p values must be greater than zero and first must be less than or equal to last.\r"
	abort "Cannot continue -- p values must be greater than zero and first must be less than or equal to last. -  Aborting from pmfCalcs_butt_RunPMF"
endif

// 1.04F we don't have any sanity checks for the ModelError variable, but we do want to save it to the data folder.
nvar/z ModelError = $pmfDFNm +"ModelError"
if (!Nvar_exists(ModelError))
	variable/g $pmfDFNm +"ModelError" =pmfModelError	
	nvar ModelError = $pmfDFNm +"ModelError"
else
	ModelError = pmfModelError
endif
	
//  Sanity checks completed.  Let's get to work.
// Save experiment before we try to run PMF in case something bad happens when we try to run PMF.
if (saveExpAfterPMF)
	SaveExperiment	
endif

//------------------------------------------
// now we are starting with PMF
	
// make active file so that it isn't confused with another copy of pmf running
Open/p=$PMF_EXE_IGOR_PATH_NAME filenum as ACTIVE_FILE_NAME
fprintf filenum, "PMF execution began at "+date() + " "+time()+" \r"
close filenum

if (exploreOrBootstrap==1) // explore
	// $$$ AB added for keeping track
	print "// Msdata wave: "+pmfDFNm+DataMxNm
	print "// Mserror wave: "+pmfDFNm+StdDevMxNm
	// $$$
	// deal with Model error stuff 		// 1.04F
	// function call to pmfCalcs_writeMxErrFiles moved from inside pmfCalcs_runPMF_range_p_fpeak function to here.
	// write matrix.dat and std_dev.dat, and std_dev_prop.dat (overwrite any existing files)
	make/o/n=(dimsize(StdDevMx,0), dimsize(StdDevMx,1)) ModelErrorMx
	ModelErrorMx = ModelError		// a simple matrix filled with constants
	
	pmfCalcs_writeMxErrFiles(DataMx, StdDevMx, ModelErrorMx, PMF_EXE_IGOR_PATH_NAME)
	Killwaves/z ModelErrorMx	// we only need to write this to file, we don't need to keep it around.

	// !!! THIS DOES THE CALCULATION !!!
	pmfCalcs_runPMF_range_p_fpeak(DataMx, StdDevMx, SeedOrFpeak, p_min, p_max, fpeak_min, fpeak_max, fpeak_delta,PMF_EXE_IGOR_PATH_NAME)

	DeleteFile/p=$PMF_EXE_IGOR_PATH_NAME ACTIVE_FILE_NAME

	// prepare for the next panel, the viewing of results 
	// pmfResults_viewPanel()
	svar plot_pmfDFNm = root:pmf_Plot_globals:pmfDFNm
	svar plot_DataMxNm = root:pmf_Plot_globals:DataMxNm
	svar plot_StdDevMxNm = root:pmf_Plot_globals:StdDevMxNm

//		// simulate a popmenu action
//		pmfResults_ChooseDataDF("dataDFSel",nan,pmfDFNm)
//		plot_pmfDFNm = pmfDFNm
//		plot_DataMxNm = DataMxNm
//		plot_StdDevMxNm =StdDevMxNm
//		//  I always forget... when we want an option to appear in the popmenu, set the mode value.
//		PopupMenu vw_pop_pmfPlot_DataMxNm, mode=WhichListItem(plot_DataMxNm,  waveList("*", ";", "DIMS:2"))+1
//		PopupMenu vw_pop_pmfPlot_StdDevMxNm, mode=WhichListItem(plot_StdDevMxNm,  waveList("*", ";", "DIMS:2"))+1
//		gen_pop_pmfStr("vw_pop_pmfPlot_DataMxNm",WhichListItem(plot_DataMxNm,  waveList("*", ";", "DIMS:2"))+1,DataMxNm)

	DoWindow/K PMF_PerformCalc_Panel

else		// bootstrap
	
	abortStr="MPaux_RUN_PMF():\r\rbootstrap method not supported by MaS-PET -> use PET panel instead"
	MPaux_abort(AbortStr)
	//pmfCalcs_runPMF_bootstrap(dataMx, StdDevMx,PMF_EXE_IGOR_PATH_NAME)

endif

if (saveExpAfterPMF)
	SaveExperiment	
endif

END

//======================================================================================
//======================================================================================

// Purpose:		create tseries wave with offset using the information in the Main Panel	
//					first set data folder in MaS-PET Main Panel
//					use this AFTER PMF calculations were done (i.e., Waves4PMF exists)
// Input:			from Main MaS-PET Panel
// Output:		tseries wave with i*200 offset
// called by:	stand-alone

FUNCTION MPaux_tseriesOffset()

// get info from MaS-PET Panel
SVAR FolderStr=root:APP:combiName_STR

// use wave names stored in Waves4PMF
Wave/T Waves4PMF=$(FolderStr+":Waves4PMF")
Wave/T Wavenames=root:app:dataWavenames
MPaux_check4Waves4PMF(FolderStr,"stand alone",Wavenames)

// get data waves
Wave Tdesorp=$(FolderStr+":"+Waves4PMF[%Tname])	// tseries
Wave idxSample=$(FolderStr+":"+Waves4PMF[%idxSamplename])	// idxsample

// calcaulate new values
Make/D/O/N=(numpnts(Tdesorp)) $(FolderStr+":"+Waves4PMF[%Tname]+"_offset")
Wave Tdesorp_offset=$(FolderStr+":"+Waves4PMF[%Tname]+"_offset")
Tdesorp_offset=Tdesorp

Variable ii
FOR (ii=0;ii<dimsize(idxSample,0);ii+=1)
	Tdesorp_offset[idxSample[ii][0],idxSample[ii][1]]+=ii*200
ENDFOR

// and alert user
String alertStr="To use new Tdesorp values, User must change 'Tname' entry in both waves in table to:\r\r"
alertStr+=Waves4PMF[%Tname]+"_offset"
Doalert 0, alertStr

// open table and simple graph with waves to check
Killwindow/Z Waves4PMF_table
Killwindow/Z Graph_Tdesorp_offset

Edit/N=Waves4PMF_Table /W=(0,0,500,200) Waves4PMF.ld, wavenames.ld as "Waves4PMF_Table"

Display/W=(0,250,500,600) tdesorp,tdesorp_offset as "Graph_Tdesorp_offset"
Dowindow/C Graph_Tdesorp_offset

ModifyGraph rgb(Tdesorp)=(0,0,0)

Legend/C/N=text0/A=LT
Label left,"Tdesorp values"
Label bottom, "point number"

END

//======================================================================================
//======================================================================================


//======================================================================================
//======================================================================================

//========================================
//		Ion Tseries plotter procedures
//========================================

//======================================================================================
//======================================================================================


// Purpose:	plot and compare several thermogram scan MS data sets
//				waves must have same name in all selected folders 
//				IF different ion lists are detected a copy of the data is created with a combined ion list
//				Names of all connected procedures start with "MPaux_CTP_"
// Input:		select folders to be plotted in gui
//				MSname		String name of wave with MS data (2D)
//				MZname		String name of wave with MZ data
//				Tdesorpname	String name of wave with Tdesorp data
// Output:	plot with slider
//				root:Folder with parameters
//called by:	MPbut_step1_button_control() -> but_compareThermoPlot  or stand-alone

FUNCTION MPaux_CTP_compThermoPlot_main(MSname,MZname,Labelname,TdesorpName,ErrName)

String MSname,MZname,Labelname,TdesorpName,ErrName

// clear out everything in root:App:Thermoplotter:commonData
// this is important to ensure that the folder selection widget has the right name for its house keeping data
IF (wintype("ThermoCompare")!=0)
	Killwindow ThermoCompare
ENDIF

// set Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution=?"
Variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

// prepare folder to store info
MPaux_NewSubfolder("root:App:ThermoPlotter",1)
String/G NameMS=MSname
String/G NameErr=ErrName
String/G NameMZ=MZname
String/G NameLabel=Labelname
String/G NameTdesorp=TdesorpName
Variable/G nos
Variable/G plotError=0

// check for abortSTr variable
SVAR abortStr=root:APP:abortSTr
IF (!SVAR_Exists(AbortStr))
	String/G ::abortStr=""
	SVAR abortStr=root:APP:abortSTr
ENDIF

// build folder selector gui
MPaux_CTP_SelectFolder()

// reset Panel resolution to default
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)


END

//======================================================================================
//======================================================================================
// Purpose:		create Folder selection widget for thermogram plotter
//					the OK button will trigger the actual plotting
//					this is relies on the <WaveselectorWidget> code

// Input:			selection via widget
// Output:		folder selctor widget	
//
// called by:	MPaux_CTP_compThermoPlot_main()


Function MPaux_CTP_SelectFolder()

String panelName = "DatafolderSelector_Panel"

IF (WinType(panelName) == 7)
	// if the panel already exists, show it
	DoWindow/F $panelName
ELSE
	// doesn't exist, make it
	NewPanel/N=$panelName/W=(181,179,471,510)/K=1 as "Select data folders"
	// instructions
	TitleBox title0 title="select folders for Plotting and click \"go\"", frame=0,pos={9,10}
	// list box control doesn't have any attributes set on it
	ListBox DatafolderList,pos={9,30},size={273,260}
	
	// This function does all the work of making the listbox control into a
	// Wave Selector widget. Note the optional parameter that says what type of objects to
	// display in the list. (4 is datafolders only)
	MakeListIntoWaveSelector(panelName, "DatafolderList", content = 4)

	// sort folder list alphabetical (not by creation time)
	Wave/T ListWave=root:Packages:WM_WaveSelectorList:WaveSelectorInfo0:ListWave
	Make/T/FREE /N=(dimsize(ListWave,0)) ListWave1,ListWave2
	Make/FREE /N=(dimsize(ListWave,0)) ListWaveIdx
	
	ListWave1=ListWave[p][1][0]	// short FOlder names
	ListWave2=ListWave[p][1][1]	// full Folder path
	
	MakeIndex ListWave2,ListWaveIdx	// use index sort because of 2D wave
	IndexSort ListWaveIdx,ListWave1,ListWave2
	
	ListWave[][1][0]=ListWave1[p]
	ListWave[][1][1]=ListWave2[p]
	
	// action buttons
	Button but_SelectData4Plot,pos={9,300},size={90,20},proc=MPaux_CTP_butProc_ThermoComp ,title="Go"
	Button but_SortFolderList,pos={110,300},size={90,20},proc=MPaux_CTP_butProc_ThermoComp ,title="Sort Folders"
	Button but_SelectDataCancel,pos={225,300},size={60,20},proc=MPaux_CTP_butProc_ThermoComp,title="Cancel"
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		handle button actions for the thermo plotter panels
// Input:			button name
//					selected folders and MSerr names from global variables
// Output:		depends on button
// called by:	Panels created with MPaux_CTP_SelectFolder() and MPaux_CTP_selectData4Plot()


FUNCTION MPaux_CTP_butProc_ThermoComp(CtrlStruct) : buttonControl

STRUCT WMButtonAction &ctrlStruct

// button clicked and released
IF (ctrlStruct.eventCode==2)

	NVAR plotError= root:App:ThermoPlotter:plotError
	Wave/T ErrorNames=root:App:Thermoplotter:ErrorNames
	
	Variable test=0
	Variable ct=0
	String WMFolderName=""
	
	// check button type
	STRSWITCH (ctrlStruct.ctrlname)

		// Data Folder Selction Panel
		CASE "but_SelectData4Plot":	// "Go" button
			MPaux_CTP_selectData4Plot()
			BREAK
		CASE "but_SortFolderList":	// sort data folders
			MPaux_CTP_SortFolderList()
			BREAK

		//==============================
		// MSerr Name Panel
		CASE "but_MSerrName_Panel_yes":
			ploterror=1
			// reset to Panel value
			SVAR NameErr=root:App:ThermoPlotter:NameErr
			Wave/T selectedFolders=root:app:ThermoPlotter:selectedFolders // text wave with new source data
			Variable ff
			
			FOR (ff=0;ff<numpnts(selectedFOlders);ff+=1)
				ErrorNames[ff]=selectedFOlders[ff]+":"+NameErr
			ENDFOR

			BREAK
		
		CASE "but_MSerrName_Panel_yesTab":
			ploterror=1
		
			BREAK
		
		CASE "but_MSerrName_Panel_no":
			plotError=0
		
			BREAK
		CASE "but_SelectDataCancel":
			BREAK
		//default 
		DEFAULT:
			BREAK
	ENDSWITCH

	// kill window to get out
	IF (!Stringmatch(ctrlStruct.ctrlname,"but_SortFolderList"))
		Killwindow/Z MSerrName_Panel
		Killwindow/Z DatafolderSelector_Panel
		
				// remove widget data
		test=0
		
		DO
			WMFolderName=getindexedobjname("root:Packages:WM_WaveSelectorList",4,ct)
			IF (Stringmatch(WMFolderName,""))
				test=1
			ENDIF
			
			Killdatafolder/Z $("root:Packages:WM_WaveSelectorList:"+WMFolderName)
			ct+=1
		WHILE (test!=1)
	
	ENDIF
	

ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		sort the folders displayed in the folder selection widget alphanumerically
//
// Input:			Folder list in widget
// Output:		alphanumeric sorted list of folders
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_butProc_ThermoComp()


FUNCTION MPaux_CTP_SortFolderList()

Wave/T ListWave=root:Packages:WM_WaveSelectorList:WaveSelectorInfo0:ListWave
Make/T/FREE /N=(dimsize(ListWave,0)) ListWave1,ListWave2
Make/FREE /N=(dimsize(ListWave,0)) ListWaveIdx

ListWave1=ListWave[p][1][0]	// short Flder names
ListWave2=ListWave[p][1][1]	// full Folder path

MakeIndex ListWave2,ListWaveIdx	// use index sort because of 2D wave
IndexSort ListWaveIdx,ListWave1,ListWave2

ListWave[][1][0]=ListWave1[p]
ListWave[][1][1]=ListWave2[p]

END

//======================================================================================
//======================================================================================

// Purpose:		create ion tseries plot
//					this also triggers the checks for common ion lists
//					user interaction about ploting errors
//
// Input:			Folder list from widget
//					wavenames etc from FiT-PET panel globals
// Output:		copy of data padded to have a common ion list
//					slider plot of ion thermograms
//
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder()-> MPaux_CTP_butProc_ThermoComp()

Function MPaux_CTP_selectData4Plot()

SVAR abortStr=root:APP:abortSTr

// make sure we are in right data folder
setdatafolder root:App:ThermoPlotter

// prepare colours for Traces
make/O/D/N=(22,3) colourTable=0

colourTable[0][0]= {0,255,0,0,153,153,255,0,0,255,255,0,102,172.191,255,153,191.296,102.767,191.249,255,0.00389105,153}
colourTable[0][1]= {0,0,153,0,0.00389105,153,63.7549,255,255,170,255,190.759,102,114.755,212.479,50.9767,255,0.00389105,206.829,191.249,135.475,152.992}
colourTable[0][2]= {0,0,0,255,122.401,153,216.922,0,255,0,0,255,102,229.502,127.502,0.00389105,127.502,204,255,242.249,204,0.00389105}		

colourTable*=257

// get info about which folder is selected
Wave/T ListWave=root:Packages:WM_WaveSelectorList:WaveSelectorInfo0:ListWave
Wave SelWave=root:Packages:WM_WaveSelectorList:WaveSelectorInfo0:SelWave

Make/FREE/T/O/N=(dimsize(listWave,0)) FolderPathWave
FolderPathWave=ListWave[p][1][1]	// make 1D wave with full path to folders
Make/FREE/D/O/N=(dimsize(listwave,0)) Selected
Selected=SelWave[p][1]

// catch if no folder was selected
IF (sum(selected)==0)
	abortSTr= "MPaux_CTP_selectData4Plot():\r\rno folder was selected -> try again or close panel with X"
	MPaux_abort(AbortStr)
ENDIF

Extract/T FolderPathWave, SelectedFolders, Selected>0

// close gui
Killwindow/Z DatafolderSelector_Panel

// get global values
NVAR nos
NVAR plotError
SVAR NameMS
SVAR nameErr
SVAR NameMZ
SVAR NameTdesorp
SVAR NameLabel		

Wave/T selectedFolders	// wave containing datafolder names
nos=numpnts(selectedFolders)	// numer of sected folders

Variable ff

//prompt user for error wave

Make/T/O/N=(nos) ErrorNames=""
FOR (ff=0;ff<nos;ff+=1)
	ErrorNames[ff]=selectedFOlders[ff]+":"+NameErr
ENDFOR

KillWINdow/Z MSerrName_Panel

NewPanel/W=(60,50,400,400)/N=MSerrName_Panel/K=2		// panel can only be killed with buttons!
TitleBox MSerrName_label0 title="Do you want to plot error values as well?",pos={10,10}, fstyle=1,frame=0,font="Arial",Fsize=14
Button but_MSerrName_Panel_yes, Title="yes, use APP name", size={120,25}	, pos={10,30}, proc=MPaux_CTP_butProc_ThermoComp
Button but_MSerrName_Panel_yesTab, Title="yes, use Table below", size={120,25}	, pos={140,30}, proc=MPaux_CTP_butProc_ThermoComp
Button but_MSerrName_Panel_no, Title="No", size={60,25}	, pos={270,30}, proc=MPaux_CTP_butProc_ThermoComp

Edit/HOST=MSerrName_Panel/W=(10,60,330,340) ErrorNames
RenameWindow #,Errornames_table
ModifyTable/W=MSerrName_Panel#Errornames_table width(ErrorNames)=120

// halt execution until MSerrName_Panelpanel is killed
PauseForUSER MSerrName_Panel

//Check ion lists of selected experiments 
//Create data including all ions in all selected runs in new data folder, if necessary
MPaux_CTP_CreateCommonIonList(NameMS,NameLabel,NameMZ,NameTdesorp,ErrorNames,"root:App:ThermoPlotter:CommonData",selectedFolders)

setdatafolder root:App:ThermoPlotter	// go back to thermoPlotter folder

Wave/T selectedFolders_new=root:APP:ThermoPlotter:selectedFolders_New // text wave with new source data

selectedFolders=selectedFolders_New[p]

Make/T/O/N=(nos) XNames="",SliderNames="",MatrixNames="",LegNames="",TraceNames_MS="",TraceNames_err="",LabelNames=""
Make/D/O/N=(nos) SliderLength	// how many elements in sliderWave

//plot
//--------
//create plot with slider and button for column/row switch
IF (wintype("ThermoCompare")!=0)
	Killwindow ThermoCompare
ENDIF

Display/K=1/W=(50,50,600,400) as "ThermoCompare";Delayupdate
DoWindow/C ThermoCompare
Showinfo
Setwindow ThermoCompare,hook(TChook)=MPaux_CTP_Hook

// loop through selected folders
String LegendStr=""
Variable CurrentPlotError
FOR (ff=0;ff<nos;ff+=1)
	Xnames[ff]=selectedFolders[ff]+":"+NameTdesorp
	SliderNames[ff]=selectedFOlders[ff]+":"+NameMZ
	Matrixnames[ff]=selectedFOlders[ff]+":"+NameMS

	Labelnames[ff]=selectedFOlders[ff]+":"+NameLabel
	LegNames[ff]=stringfromlist(Itemsinlist(selectedFOlders[ff],":")-1,selectedFOlders[ff],":")	// get folder name for legend		
	
	// assign wave
	Wave xwave = $Xnames[ff]
	Wave matrixWave= $Matrixnames[ff]
	Wave sliderWave= $SliderNames[ff]
	Wave/T labelWave= $Labelnames[ff]
	
	Wave/Z ErrorWave= $Errornames[ff]
	
	IF (!Waveexists(ErrorWave))	// check if MSerr wave is present
		CurrentplotError=0
	ELSE
		CurrentPlotError=plotError
	ENDIF
	
	// check length of slider wave
	SliderLength[ff]=numpnts(sliderWave)
	Variable noc
	String alertStr=""
	
	IF (SliderLength[ff]>0 && ff>0 && SliderLength[ff]!=SliderLength[ff-1])	// catch different length of selected slider wave
		alertStr="selected slider direction wave in folder "+selectedFolders[ff]+" is "
		IF (SliderLength[ff]>SliderLength[ff-1])	// current one longer than previous
			alertStr+=num2str( SliderLength[ff]-SliderLength[ff-1])+ " elements longer "
			noc=SliderLength[ff]-SliderLength[ff-1]
		ELSE
			alertStr+=num2str( SliderLength[ff-1]-SliderLength[ff])+ " elements shorter "
			noc=SliderLength[ff-1]-SliderLength[ff]
		ENDIF

		//"selected slider direction wave in folder "+selectedFolders[ff]+"has different length from previous one "+selectedFolders[ff-1]
		alertStr+=" than previous one in folder "+selectedFolders[ff]+"\r"
		alertStr+="abort (cancel), add missing ones before (yes) or after (no) data block?"
		
		DoAlert 2,AlertStr
		
		SWITCH(V_flag)	// numeric switch
			CASE 1:	// YES
				IF (SliderLength[ff]<SliderLength[ff-1])
					// current one is shorter
					insertPoints/M=1 0,(noc), matrixWave
				ELSE
					// current one is longer
					Wave matrixWave1= $Matrixnames[ff-1]
					insertPoints/M=1 0,(noc), matrixWave1
				ENDIF
				BREAK
			CASE 2:	// NO
				IF (SliderLength[ff]<SliderLength[ff-1])
					// current one is shorter
					insertPoints/M=1 dimsize(matrixWave,1),noc, matrixWave
				ELSE
					// current one is longer
					Wave matrixWave1= $Matrixnames[ff-1]
					insertPoints/M=1 dimsize(matrixWave1,1),(noc), matrixWave1
				ENDIF
				BREAK
			DEFAULT:	// CANCEL
				Abort
		ENDSWITCH
	
	ENDIF
	
	IF (SliderLength[ff]==0)// catch empty wave
		alertStr="selected slider direction wave in folder "+selectedFolders[ff]+" is empty.\rContinue?"
		DoAlert 1,alertStr
		IF (V_Flag==2)
			Abort		
		ENDIF
	ELSE
		// do the plot
		Appendtograph matrixWave[][0] vs xWave
		String tracelist=TraceNameList("ThermoCompare","",1)
		TraceNames_MS[ff]=StringfromList(Itemsinlist(tracelist)-1,traceList)		// last entry is most recent
		
		IF (CurrentplotError==1)	// append error if present
			Appendtograph ErrorWave[][0] vs xWave
			tracelist=TraceNameList("ThermoCompare","",1)
			TraceNames_err[ff]=StringfromList(Itemsinlist(tracelist)-1,traceList)			// last entry is most recent
		ENDIF
		
		IF (plotError==1 && CurrentPloterror==0)
			print "unable to plot error: Wave "+ErrorNames[ff]+" not found"
		ENDIF
		
		// set up legend
		LegendStr+="\s("+TraceNames_MS[ff]+") "+LegNames[ff]+"\r"
		
		// set colour
		IF (ff<22)	// colour table as 10 entries
			ModifyGraph rgb($TraceNames_MS[ff])=(colourTable[ff][0],colourTable[ff][1],colourTable[ff][2])
			
			IF (CurrentplotError==1)
				ModifyGraph rgb($TraceNames_err[ff])=(colourTable[ff][0],colourTable[ff][1],colourTable[ff][2])
				Modifygraph lStyle($TraceNames_err[ff])=3
			ENDIF
		ENDIF
	ENDIF
ENDFOR

//make pretty
ModifyGraph lsize=2, tick=2,mirror=1,fStyle=1,axThick=2,ZisZ=1,standoff=0,notation=1;DelayUpdate
SetAxis left 0,*
SetAxis bottom, 0,*

Label left "signal"
Label bottom "Tdesorp / C"

// Check if Time is used (first value in xWave > 7e5)
IF (xWave[0]>7e5)
	SetAxis bottom, *,*
	Label bottom "Time"
ENDIF

// name for display
Make/O/T/N=(numpnts(sliderWave)) Names4display=""
Names4display+=num2Str(sliderWave[p])

Make/O/T/N=(numpnts(labelWave)) Labels4display=""
Labels4display+=(labelWave[p])

LegendStr=removeEnding(LegendStr, "\r")
Legend/N=Legend0 LegendStr

//---------------------------------
//slider and button
Variable/G sliderSet=0
Variable/G sliderMax=numpnts(SliderWave)-1
Variable/G useErrorBars=0

ControlBar/W=ThermoCompare 50
Slider  sliderMatrix Win=ThermoCompare,size={300,55},vert=0, limits={0,(SliderMax),1},variable=SliderSet,proc=MPaux_CTP_ThermoSlider 
SetVariable SetTrace Win=ThermoCompare, title="selected Ion MZ",pos={328,3},size={200,20},value= Names4display[sliderSet],noedit=1, noproc
SetVariable SetTraceChemLabel Win=ThermoCompare, title="Ion Label",pos={415,25},size={155,20},value= Labels4display[sliderSet],noedit=1, noproc
SetVariable SetTraceNo Win=ThermoCompare, title="No.",pos={328,25},size={85,20}, limits={0,(SliderMax),1},value= SliderSet, proc=MPaux_CTP_ThermoSliderButton

// add checkbox if errors are plotted
IF (CurrentplotError==1)
	checkbox cb_errorBars, pos={610,25}, title="error bars",value=useErrorBars,fsize=14,frame=0,font="Arial", proc=MPaux_CTP_errorCHeckbox
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		handle slider change for ion thermogram plot	

// Input:			change from slider
// Output:		changed plot
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()	

Function MPaux_CTP_ThermoSlider(name,value,event)	: sliderControl

String name	// name of this slider control
Variable value	// value of slider
Variable event	// bit field: bit 0: value set; 1: mouse down, //   2: mouse up, 3: mouse moved

IF(event&1)
	MPaux_CTP_SliderChanged(value)
ENDIF
END

//======================================================================================
//======================================================================================

// Purpose:		handle change from ion number for ion thermogram plot	

// Input:			change from variable
// Output:		changed plot
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()		

Function MPaux_CTP_ThermoSliderButton(ctrlName,varNum,varStr,varName) : SetVariableControl

String ctrlName
Variable varNum
String varStr
String varName

ControlInfo /W=ThermoCompare SetTraceNo

MPaux_CTP_SliderChanged(V_value)

END

//======================================================================================
//======================================================================================

// Purpose:		change the displayed ion in ion thermogram plot	

// Input:			value:		idx for curernt ion for plotting
// Output:		changed plot
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()	-> MPaux_CTP_ThermoSlider() or MPaux_CTP_ThermoSliderButton()


FUNCTION MPaux_CTP_SliderChanged(value)

Variable Value

Variable ff

NVAR nos=root:App:ThermoPlotter:nos
NVAR plotError=root:App:ThermoPlotter:plotError
NVAR useErrorBars=root:App:ThermoPlotter:useErrorBars

Wave/T Xnames=root:App:ThermoPlotter:Xnames
Wave/T Matrixnames=root:App:ThermoPlotter:Matrixnames
Wave/T ErrorNames=root:App:ThermoPlotter:ErrorNames
Wave/T Names4display=root:App:ThermoPlotter:Names4display
Wave/T TraceNames_MS=root:App:ThermoPlotter:TraceNames_MS
Wave/T TraceNames_err=root:App:ThermoPlotter:TraceNames_err
Wave/T LegNames=root:App:ThermoPlotter:LegNames

String LegendStr=""

// loop throughtraces on graph
FOR (ff=0;ff<nos;ff+=1)
		
	// assign wave
	Wave xwave = $Xnames[ff]
	Wave matrixWave= $Matrixnames[ff]
	Wave errorWave= $errornames[ff]
			
	// change wave in plot
	replaceWave /W=ThermoCompare trace=$TraceNames_MS[ff], matrixWave[][value] 
	
	IF (ploterror==1 && Waveexists(errorWave))
		// change error line value
		replaceWave /W=ThermoCompare trace=$TraceNames_err[ff], errorWave[][value] 
		// change error bar value
		IF (useErrorBars==1)
			ErrorBars/W=ThermoCompare $Tracenames_MS[ff] Y,wave=(errorWave[][value],errorWave[][value])
		ENDIF
	ENDIF
	
	// rebuild plot legend
	LegendStr+="\s("+TraceNames_MS[ff]+") "+LegNames[ff]+"\r"
		
ENDFOR

// redraw legend
LegendStr=removeEnding(LegendStr, "\r")
Legend/N=Legend0/K
Legend/N=Legend0 legendStr

//adjust name
SetVariable SetTrace,Win=ThermoCompare,value=Names4display[value]
SetVariable SetTraceChemLabel,Win=ThermoCompare,value=Labels4display[value]

END

//======================================================================================
//======================================================================================

// Purpose:		switch to plot errors as error bars instead of individual lines
// Input:			chekcing status of checkbox
// Output:		change plotting style of error values in CTP plot
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()	

FUNCTION MPaux_CTP_errorCheckbox(ctrlStruct)

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)	// only act on mouse click release
	// get waves with info for Graph
	Wave/T ErrorNames=root:App:ThermoPlotter:ErrorNames	// full path to error waves
	Wave/T TraceNames_MS=root:App:ThermoPlotter:TraceNames_MS	// trace names of MSdata line
	Wave/T TraceNames_err=root:App:ThermoPlotter:TraceNames_err	// trace name of MSerr line

	NVAR SliderSet=root:APP:ThermoPlotter:SliderSet	// selected ion
	NVAR useErrorBars=root:App:ThermoPlotter:useErrorBars	// checkbox status
 
 	useErrorBars=ctrlStruct.checked
 	
	//loop through traces
	Variable ii
	FOR (ii=0;ii<numpnts(Tracenames_MS);ii+=1)
		
		// show/hide error lines
		Modifygraph/W=ThermoCompare hideTrace($tracenames_err[ii])=useErrorBars
		
		// show/hide error bars
		IF (useErrorBars==1) // selected -> plot as error bars
			// show
			Wave CurrentErr=$ErrorNames[ii]
			ErrorBars/W=ThermoCompare $Tracenames_MS[ii] Y,wave=(CurrentErr[*][SliderSet],CurrentErr[*][SliderSet])
		ELSE // unselected -> plot as line
			// hide error bars
			ErrorBars/W=ThermoCompare $Tracenames_MS[ii] OFF
		ENDIF
		
	ENDFOR
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		handle closing of ThermoCompare window -> delete associated waves

// Input:			datastructure with info about event
// Output:		kills window and deletes waves
// called by:	MPaux_CTP_compThermoPlot_main() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()	 

FUNCTION MPaux_CTP_Hook(dataStruct)

STRUCT WMWinHookStruct &dataStruct

Variable HookResult=0

SWITCH (dataStruct.eventCode)
	CASE 2:	// window is killed
		
		// Killwindow does not release waves -> data cannot be deleted
		
		//-> loop through traces and remove
		String Alltraces=TracenameList(dataStruct.winName,";",1)
		Variable ii
		FOR (ii=Itemsinlist(AllTraces)-1; ii>-1;ii-=1)	// start withh last becasue tracenames can change
			removefromgraph/W=$dataStruct.winName/Z $(Stringfromlist(ii,Alltraces))
		ENDFOR
		
		// kill window and data folder
		Killwindow/Z ThermoCompare
		killdatafolder/Z root:APP:ThermoPlotter:commonData
		
		// remove package data (this will remove any widgetselector related data
		Variable test=0
		Variable ct
		DO
			String WMFolderName=getindexedobjname("root:Packages:WM_WaveSelectorList",4,ct)
			IF (Stringmatch(WMFolderName,""))
				test=1
			ENDIF
			
			Killdatafolder/Z $("root:Packages:WM_WaveSelectorList:"+WMFolderName)
			ct+=1
		WHILE (test!=1)
		

		BREAK
		
ENDSWITCH

RETURN hookResult

END

//==================================================================================
//==================================================================================

// Purpose:		Checks if FIGAERO CIMS data in multiple folders have same ion list
//					if ion lists are different, a copy of the data is created in a new folder
//					only works with FiT-PET Panel

// Input:			MSdataM: 			string with name of MSdata wave
//										this can contain a subfolder (eg. using smoothed MSdata)
//					LabelW				string with name of ion Label wave
//					amuW				string with name of exact mz wave
//					TdesorpW:			string with name of desorption temperature wave
//					ErrorNames:		string with full path of MSerr wave (will be ignored if error does not exist)
//					ResultFolder:	string with folder for newly created data with common ion list
//					SelectedFolder:	text wave with full paths to folder to be compared
//				
// Output:		new data in resultfolder
//					SelectedFolder_New:	text wave with path to "newly" created data
//
// called by: 	MPaux_CTP_compThermoPlot_main_APP() -> MPaux_CTP_SelectFolder() -> MPaux_CTP_selectData4Plot()


Function MPaux_CTP_CreateCommonIonList(MSdataM,LabelW,amuW,TdesorpW,ErrorNames,ResultFolder,SelectedFolder)

String MSdataM	//string name of MS data wave (2D)
String LabelW	//string name of ion label wave
String amuW		//string name MZ values wave
String TdesorpW	//string name T desorption wave
Wave/T ErrorNames	// string name of error wave (2)
String ResultFolder	//path of the folder of new combined data
Wave/T SelectedFolder // text wave of selected source data

NVAR plotError=root:App:ThermoPlotter:plotError	// user selected if they want to plot error or not
SVAR abortSTr=root:APP:abortSTr

Variable MSerrExits=0								// indicator for current error Wave

SetDataFolder root:

// check passed folder names for ':' at end
ResultFolder=removeending(resultfolder,":")

// check passed MSdata name for leading ':' (in case MS data is in a subfolder)
IF (Stringmatch(MSdataM[0],":"))
	MSdataM=MSdataM[1,strlen(MSdataM)-1]
ENDIF

// remove existing Thermoplotter window
// clear out everything in root:App:Thermoplotter:commonData
IF (wintype("ThermoCompare")!=0)
	Killwindow ThermoCompare
ENDIF

Killdatafolder/Z $resultFolder

// make output wave
Duplicate/O/T SelectedFolder,root:app:ThermoPlotter:SelectedFolders_new
Wave/T SelectedFolders_new=root:app:ThermoPlotter:SelectedFolders_new
MPaux_NewSubfolder(ResultFolder,0)


Variable NoF=numpnts(SelectedFolder) //Number of Folders

//Get elemental number and reconstruct the MZ Label
Variable ff
String FolderList="" //string list of selected folder (source folder)
String NewFolderList="" //string list of result folder (result folder)
string MZLabel_R_List="" // string list of resconstructed ion label
string MZ_R_List=""		//string list of reconstructed MZ values

String currentFolder=""


// loop through folders to create combined ion list
FOR (ff=0;ff<NoF;ff+=1)
	
	//Prepare folder list and wave list for calcElementFromLabel
	FolderList+=SelectedFolder[ff]+";" 
	NewFolderList+=replacestring("root:",SelectedFolder[ff],ResultFolder+":")+";"
	
	currentFolder=StringFromList(ff,NewFolderList)
	
	MZLabel_R_List+=currentFolder+":"+LabelW+"_R"+";" //string list of reconstructed ion label
	MZ_R_List+=SelectedFolder[ff]+":"+amuW+";" //string list of reconstructed MZ values
	
	// remove existing datafolder content and set folder
	IF (Datafolderexists(CurrentFolder))
		Setdatafolder $currentFolder
	ELSE
		MPaux_NewSubfolder(currentFolder,1)
	ENDIF
	
	// check that all data waves exist in source folder
	String Waves4check=SelectedFolder[ff] + ":"+MSdataM+";"+SelectedFolder[ff] + ":"+LabelW+";"+SelectedFolder[ff] + ":"+amuW+";"
	Waves4Check+= SelectedFolder[ff] + ":"+TdesorpW+";"
	
	IF(!MPaux_CHeckWavesFromList(Waves4Check))	// returns 0 if one wave does not exist
		Wave NonExistIDX
		Variable ww=0
		
		abortStr= "MPaux_CTP_CreateCommonIonList():\r\rThese waves were not found:\r\r"
		
		FOR (ww=0;WW<numpnts(NonExistIDX);ww+=1)
			abortStr+=  Stringfromlist(NonExistIDX[ww],Waves4Check)+"\r"
		ENDFOR

		MPaux_abort(AbortStr)
	ENDIF
	
	//duplicate ion labels and ExactMZ
	Wave/T MZLabel=$(SelectedFolder[ff]+":"+LabelW)
	MAke/O/T/N=(numpnts(MZLabel)) $(LabelW+"_R")	// legacy from Rex procedure -> _R will have the modified labels for Unknown ions
	Wave/T MZLabel_R=$(LabelW+"_R")
	MZLabel_R=MZLabel
	
	//Create Labels for 'Unknown' ions	
	Wave MZ=$(SelectedFolder[ff]+":"+amuW)
	
	Extract/INDX/FREE MZLabel_R,INDX_U,stringmatch(MZLabel_R[p],"")==1 //get the row index
	
	Variable ii
	
	FOR(ii=0;ii<numpnts(INDX_U);ii+=1)	// loop through 'unknown' ions in ion list
		
		Variable temp_1=floor(MZ[INDX_U[ii]]) //floor part of the number
		Variable temp_2=round((MZ[INDX_U[ii]]-floor(MZ[INDX_U[ii]]))*10000)/10000 //round 4 digits. Because num2str is limited to only 5 digits
		String temp_digits=num2str(temp_2)
		
		IF (temp_2>0.99995) //catch rounding up to next integer
			temp_1+=1
		ENDIF
		
		MZLabel_R[INDX_U[ii]]="U_"+num2str(temp_1)+temp_digits[1,strlen(temp_digits)-1]
	ENDFOR
	
ENDFOR	// folder loop

setdatafolder :: //go back to the main level

//Check if there is a need to construct a total peak list
Variable refrow=numpnts($(StringFromList(0,MZLabel_R_List))) //ref wave is the wave in the 1st folder

Concatenate/T/O/NP=0 MZLabel_R_List, Total_MZLabel

FindDuplicates/RT=Total_MZLabel_dupsR Total_MZLabel //Remove duplicates

Wave/T Total_MZLabel_dupsR	// wave contains all possible ions from all lists

IF ((numpnts(Total_MZLabel_dupsR)*nof)==numpnts(Total_MZLabel)) //Check if concatenated peak list is equal to number of folders times items in first ion list
	// ion list agree -> do nothing and get out
	RETURN	-1 
ELSE
	Print "MPaux_CTP_CreateCommonIonList(): Peak Lists do not match -> creating data copy with padding for missing ions"
ENDIF

//------------------------------------------
// create comomn ion list data
// name of common ion list: Total_MZLabel_dupsR

// get element Num Wave for common ion list
MPaux_calcElementFromLabel(Total_MZLabel_dupsR)
Wave ElementNum_dubsR=ElementNum

// recalcalculate exactMZ
Make/O/D/N=(numpnts(Total_MZLabel_dupsR)) Total_MZ_dupsR

// Construct common ion list including all ion labels in all selected runs
FOR (ff=0;ff<NoF;ff+=1)
	// reset wave references
	Wave/T MZlabel_C=$""
	Wave/T MZlabel=$""
	Wave MZ_C=$""	
	Wave MZ=$""	
	Wave MSdata=$""
	Wave MSdata_C=$""
	Wave T_orig=$""
	Wave MSerr=$""
	Wave MSerr_C=$""
	
	// go to current new datafolder
	currentFolder=StringFromList(ff,newFolderList)
	String SourceFolder=StringFromList(ff,FolderList)
	
	setdatafolder currentFolder

	//Get source waves in source data folders
	Wave/T MZLabel=$(SourceFolder+":"+LabelW)
	Wave MZ=$(SourceFolder+":"+amuW)
	Wave MSdata=$(SourceFolder+":"+MSdataM)
	Wave T_orig=$(SourceFolder+":"+TdesorpW)
	
	// duplicate Tdesorp -> always stas as is
	Duplicate/O T_orig,$TdesorpW
	
	//check if ionlabel waves are identical -> just copy data
	Wave ElementNum_C=$""
	
	MPaux_calcElementFromLabel(MZLabel)
	Wave ElementNum_C=ElementNum
	
	String MSerrName=Stringfromlist(Itemsinlist(Errornames[ff],":")-1,Errornames[ff],":")
			
	IF (equalWaves(ElementNum_dubsR,ElementNum_C,1))
		// just copy and go to next	
		Duplicate/O/T MZLabel,$LabelW
		Duplicate/O MZ,$amuW
		Duplicate/O MSdata,$MSdataM
		
		Wave MZ_C=$amuW		
		Wave/T MZlabel_C=$LabelW
		Wave MSdata_C=$MSdataM
		
		// iff error is selected
		IF (plotError==1)
			
			// catch if MSerr is missing
			IF (Waveexists($(Errornames[ff])))
				Wave MSerr=$ErrorNames[ff]
				
				Duplicate/O MSerr,$MSerrName
				Wave MSerr_C
			ELSE
				print "MPaux_CTP_CreateCommonIonList(): no Error wave found: "+ 	Errornames[ff]	
			ENDIF
		
		ENDIF

		//set MS values
		Total_MZ_dupsR=MZ_C
	ELSE
	
		// create common ion list
		
		// containers for data
		Variable noi=numpnts(Total_MZLabel_dupsR)	// number of ions
		Variable not=numpnts(T_orig)					// number of T points
		Make/O/D/N=(noi) $amuW
		Make/O/T/N=(noi) $LabelW
		Make/O/D/N=(not,noi) $MSdataM

		Wave MZ_C=$amuW		
		Wave/T MZlabel_C=$LabelW
		Wave MSdata_C=$MSdataM
		
		MZ_C=NaN
		MZLabel_C=Total_MZlabel_dupsR
		MSdata_C=NaN
		
		IF (plotError==1)	// if error was selected
			IF (Waveexists($(Errornames[ff])))
				MSerrExits=1
				
				Make/O/D/N=(not,noi) $MSerrName
				Wave MSerr=$ErrorNames[ff]
				Wave MSerr_C=$MSerrName
				MSerr_C=0		
			ELSE
				MSerrExits=0
			ENDIF
		
		ENDIF
		
		FOR(ii=0;ii<numpnts(MZlabel);ii+=1)	// loop through all ions
			// find label from duplicated
			String searchStr
			searchStr="(?i)"+MZlabel[ii]
			Grep/INDX/Q/E=searchStr Total_MZLabel_dupsR		// find label from ion label source wave in combined list
			Wave W_index
			
			IF (V_value==1)	// entry was found  
				// add into total MZ wave 
				Total_MZ_dupsR[V_startParagraph]=MZ[ii]
				
				//store sample specific data
				Msdata_C[][V_startParagraph]=MSdata[p][ii]
				
				IF (plotError==1 && MSerrExits==1)
					Mserr_C[][V_startParagraph]=MSerr[p][ii]
				ENDIF
			ELSEIF (V_value>=0)

				// multiple entries found (can happen for small ions ("HIO-" -> CHIO-)
				// search for exact match
				Variable mm, ct=0
				FOR (mm=0;mm<numpnts(W_index);mm+=1)
					
					IF (StringMatch(MZlabel[ii],Total_MZLabel_dupsR[W_index[mm]]))
						// add into total MZ wave 
						Total_MZ_dupsR[W_index[mm]]=MZ[ii]
						
						//store sample specific data
						Msdata_C[][W_index[mm]]=MSdata[p][ii]
						
						IF (plotError==1 && MSerrExits==1)
							Mserr_C[][W_index[mm]]=MSerr[p][ii]
						ENDIF

						ct+=1
					ENDIF
			
				ENDFOR

				// still problems with finding ion label
				IF (ct!=1)
					abortSTr="MPaux_CTP_CreateCommonIonList():\r\rProblem with locating ion labels "
					MPaux_abort(AbortStr)
				ENDIF
			ENDIF
		ENDFOR	// ion loop
		
	ENDIF
	
	//adding note to the combined waves
	String notestring="data with combined ion list\r"+FolderList
	Note MZ_c,notestring
	Note MZLabel_c,notestring
	Note MSdata_c,notestring
	
	IF (plotError==1 && MSerrExits==1)
		Note MSerr_c,notestring
	ENDIF
	
	// Calculate element numebrs for new ion list
	MPaux_calcElementFromLabel(MZlabel_c) 
	
	//update errornames wave
	errornames[ff]=stringfromlist(ff,NewFolderList)+":"+MSerrName

	
ENDFOR	// folder loop

// handle MZ wave
FOR (ff=0;ff<nof;ff+=1)	// folder loop
	//get waves
	currentFolder=StringFromList(ff,newFolderList)
	
	Wave MZ_C=$(currentFolder+":"+ amuW	)
	Wave/T MZlabel_C=$(currentFolder+":"+ LabelW)
	Wave MSdata_C=$(currentFolder+":"+ MSdataM)
		
	// set MZ
	MZ_C=Total_MZ_dupsR
	// sort by ExactMZ
	Sort Total_MZ_dupsR, MZ_C,MZLabel_C
	
	Matrixtranspose MSdata_C
	SortColumns keywaves={Total_MZ_dupsR}, sortWaves={MSdata_C}
	Matrixtranspose MSdata_C
	
	IF (plotError==1 && Waveexists($errornames[ff]))
		Wave MSerr_C=$errornames[ff]
	
		Matrixtranspose MSerr_C
		SortColumns keywaves={Total_MZ_dupsR}, sortWaves={MSerr_C}
		Matrixtranspose MSerr_C
	ENDIF
		
ENDFOR

//Change selected folder name
SelectedFolders_new=stringfromlist(p,NewFolderList)
	
// clean up
setdatafolder ::
KillWaves/Z Total_MZ,Total_MZLabel, Total_MZLabel_dupsR,Total_MZ_dupsR // cleaning up unnecessary waves

END

	
//======================================================================================
//======================================================================================

//============================================
//		Factor Ion Tseries plotter procedures
//============================================

//======================================================================================
//======================================================================================

// Purpose:	Panel for creating proper sized plot with ion thermograms of all foctors for one ion
//				user can switch between number of factors and step through ions
//				data is prepared fod all solutions but only 1 fpeak
//				names of all connected procedures start with "MPaux_FIT_"
// Input:		folderName:	name of folder to operate on
//
// Output:	plot with sliders
//				root:Folder with parameters
//
//called by:	Panel or stand-alone


FUNCTION MPaux_FIT_FactorIonTS_Main(folderName)

String FolderName

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// basic check
IF (!datafolderExists(folderName))
	
	abortStr="MPaux_FIT_FactorIonTS_Main():\r\rPMF result data folder not found:\r"+folderName
	MPaux_abort(AbortStr)
	
ENDIF

String folderPath_local="root:"+foldername
folderPath_local=replaceString("root:root:",folderPath_local,"root:")

Wave/T Waves4PMF=$(folderPath_local+":Waves4PMF")

IF (!Waveexists(Waves4PMF))
	abortStr="MPaux_FIT_FactorIonTS_Main():\r\rCannot find wave with names of datawaves used for PMF calculation:\r"+folderPath_local+":Waves4PMF"
	MPaux_abort(AbortStr)

ENDIF

Wave Gmx4D=$(folderPath_local+":Gmx4D")	// time series of factors

IF (!Waveexists(Gmx4D))
	abortStr="MPaux_FIT_FactorIonTS_Main():\r\rCannot find PMF results waves Gmx4D in folder:\r"+folderPath_local
	MPaux_abort(AbortStr)
ENDIF

// kill window if it exists (this also delete the folder!)
IF (wintype("FactorIonTS")!=0)
	Killwindow FactorIonTS
ENDIF

// create and go to folder with stuff for ionthermogram slider graph
MPaux_newsubfolder("root:APP:FactorIonTS",1)

// prepare stuff

// folder location
String/G root:APP:FactorIonTS:folderPath
SVAR FolderPath=root:APP:FactorIonTS:folderPath
FolderPath=FolderPath_local

// prepare input data
Wave Fmx4D=$(folderPath+":Fmx4D")			// factor mass spectra
Wave fpeak_map=$(folderPath+":fpeak_map")	// fpeak values in data set
Wave p_map=$(folderPath+":p_map")			// p values in data set

Wave msdata=$(folderPath+":"+Waves4PMF[%MSdataName])	// msdata wave

// check if Global variables are there already 
Variable/G root:APP:FactorIonTS:maxP		// maximum number of factors in dataset
Variable/G root:APP:FactorIonTS:Tnum		// number of (time) points
Variable/G root:APP:FactorIonTS:ionNum	// number of ions
Variable/G root:APP:FactorIonTS:solNum	// number of solutions in this set	

NVAR maxP=root:APP:FactorIonTS:maxP
NVAR Tnum=root:APP:FactorIonTS:Tnum
NVAR ionNum=root:APP:FactorIonTS:ionNum
NVAR solNum=root:APP:FactorIonTS:solNum

// set to new values
maxP=Wavemax(p_map)			
Tnum=dimsize(msdata,0)		
ionNum=dimsize(msdata,1)	
solNum=numpnts(p_map)	

String/G MSdata_name=folderPath+":"+Waves4PMF[%MSdataName]

Make/D/O/N=(Tnum,ionNum,maxP) MSreconst_plot	// wave for plotting
Make/D/O/N=(Tnum,maxP) matrix_oneion			// matrix with 1 column for each factor, rows are
Make/D/O/N=(Tnum,ionNum) residual_data			// wave with residuals, same format as MSdata

// calculate reconstructed MS for each factor number
Variable fpeak_idx=binarysearch(fpeak_Map,0)	// use fpeak=0
IF (fpeak_idx==-1)	// catch if there is no 0
	fpeak_idx=0
ENDIF

Variable ff=0,ss=0

// calculate reconstructed spectra for all factors
FOR (ff=0;ff<maxP;ff+=1)
	// check first entry NaN -> set result to 0
	IF (numtype(Fmx4D[ff][0][fpeak_idx][0])==0)
		MSreconst_plot[][][ff]=Gmx4D[p][ff][fpeak_idx][0]*Fmx4D[ff][q][fpeak_idx][0]
	ELSE
		// no entry
		MSreconst_plot[][][ff]=0
	ENDIF
	
ENDFOR	// factor loop

matrix_oneion=MSreconst_plot[p][0][q][0]	// first solution, first ion

// calculate residual
Sumdimension/D=2/Dest=temp_sum MSreconst_plot
residual_data=MSdata-temp_sum
Killwaves/Z temp_Sum

//------------------------------------------------
// make plot
MPaux_FIT_FactorIonTS_Panel()

END
//======================================================================================
//======================================================================================

// Purpose:	create actual panel for FITS
// Input:		
//
// Output:	plot with sliders
//				root:Folder with parameters
//
//called by:	MPaux_FIT_FactorIonTS_Main() or stand-alone

FUNCTION MPaux_FIT_FactorIonTS_Panel()

// set Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution=?"
Variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

// get parameters
NVAR maxP=root:APP:FactorIonTS:maxP
NVAR Tnum=root:APP:FactorIonTS:Tnum
NVAR ionNum=root:APP:FactorIonTS:ionNum
NVAR solNum=root:APP:FactorIonTS:solNum

SVAR FolderPath=root:APP:FactorIonTS:folderPath

Wave/T Waves4PMF=$(FolderPath+":Waves4PMF")

Wave p_map=$(folderPath+":p_map")			// p values in data set
Wave fpeak_map=$(folderPath+":fpeak_map")	// fpeak values in data set

Wave matrix_oneion=root:APP:FactorIonTS:matrix_oneion		// calcaulated Factor contribution
Wave residual_data=root:APP:FactorIonTS:residual_data		// calcaulated residuals
Wave/T labelWave=$(folderPath+":"+Waves4PMF[%labelName])	// ionlabels
Wave sliderWave=$(folderPath+":"+Waves4PMF[%MZName])		// ion mass
Wave xWave=$(folderPath+":"+Waves4PMF[%TName])			// desorption T
Wave msdata=$(folderPath+":"+Waves4PMF[%MSdataName])	// msdata wave

Make/T/O/N=(maxP+2)	TraceNames_MS				// names of traces in plot

// prepare colours for Traces
make/O/D/N=(22,3) colourTable=0

colourTable[0][0]= {0,255,0,0,153,153,255,0,0,255,255,0,102,172.191,255,153,191.296,102.767,191.249,255,0.00389105,153}
colourTable[0][1]= {0,0,153,0,0.00389105,153,63.7549,255,255,170,255,190.759,102,114.755,212.479,50.9767,255,0.00389105,206.829,191.249,135.475,152.992}
colourTable[0][2]= {0,0,0,255,122.401,153,216.922,0,255,0,0,255,102,229.502,127.502,0.00389105,127.502,204,255,242.249,204,0.00389105}		

colourTable*=257

//plot
//--------

// kill window if it exists 
// !!!! this will edlete the associated data because of the window hook
// => remove hook before killing window
// if called from MPaux_FIT_FactorIonTS_Main() window is already killed there!!!

IF (wintype("FactorIonTS")!=0)
	// remove hook
	SetWindow FactorIonTS, hook(FIT_Hook)=$""
	Killwindow/Z FactorIonTS
ENDIF

//create plot with slider and button for column/row switch

Newpanel/W=(50,50,1000,700)/K=1 as "FactorIonTS"
DoWindow/C FactorIonTS

// plot area
Display/W=(0,60,710,750)/HOST=FactorIonTS
RenameWindow #,FactorIonTS_plot

// set up hook function to delete Associated WAves when window is closed
SetWindow FactorIonTS, hook(FIT_Hook)=MPaux_FIT_Hook

// loop through factors
String LegendStr="\Z16"
Variable ff

FOR (ff=0;ff<maxP;ff+=1)
	
	// do the plot
	Appendtograph/W=FactorIonTS#FactorIonTS_plot matrix_oneion[][ff] vs xWave
	
	String tracelist=TraceNameList("FactorIonTS#FactorIonTS_plot","",1)
	TraceNames_MS[ff]=StringfromList(Itemsinlist(tracelist)-1,traceList)		// last entry is most recent
	
	// set up legend
	LegendStr+="\s("+TraceNames_MS[ff]+") Factor "+num2Str(ff+1)+"\r"
	
	// set colour
	IF (ff<22)	// colour table as 10 entries
		ModifyGraph/W=FactorIonTS#FactorIonTS_plot rgb($TraceNames_MS[ff])=(colourTable[ff][0],colourTable[ff][1],colourTable[ff][2])
	ENDIF
	
ENDFOR

ModifyGraph/W=FactorIonTS#FactorIonTS_plot toMode=3, mode=7,hbFill=4

// plot measured data
appendtograph/W=FactorIonTS#FactorIonTS_plot MSdata[][0] vs xwave
tracelist=TraceNameList("FactorIonTS#FactorIonTS_plot","",1)
TraceNames_MS[maxP]=StringfromList(Itemsinlist(tracelist)-1,traceList)		// last entry is most recent

ModifyGraph/W=FactorIonTS#FactorIonTS_plot toMode($TraceNames_MS[maxP-1])=0	// last factor trace
ModifyGraph/W=FactorIonTS#FactorIonTS_plot toMode($TraceNames_MS[maxP])=0, mode($TraceNames_MS[maxP])=3,msize($TraceNames_MS[maxP])=3
ModifyGraph/W=FactorIonTS#FactorIonTS_plot marker($TraceNames_MS[maxP])=19,useMrkStrokeRGB($TraceNames_MS[maxP])=1

// plot residual data
appendtograph/W=FactorIonTS#FactorIonTS_plot /L=L_res residual_data[][0] vs xwave
tracelist=TraceNameList("FactorIonTS#FactorIonTS_plot","",1)
TraceNames_MS[maxP+1]=StringfromList(Itemsinlist(tracelist)-1,traceList)		// last entry is most recent

//make it pretty
ModifyGraph/W=FactorIonTS#FactorIonTS_plot lsize=2, tick=2,mirror=1,fStyle=1,axThick=2,ZisZ=1,standoff=0,notation=1,fsize=16
SetAxis/W=FactorIonTS#FactorIonTS_plot left *,*
SetAxis/W=FactorIonTS#FactorIonTS_plot bottom, *,*

Label/W=FactorIonTS#FactorIonTS_plot left "signal"
Label/W=FactorIonTS#FactorIonTS_plot L_res "residual"

Modifygraph/W=FactorIonTS#FactorIonTS_plot axisenab(left)={0,0.7},axisenab(L_res)={0.7,1}
Modifygraph/W=FactorIonTS#FactorIonTS_plot freePos(L_res)={0,kwFraction},nticks(L_res)=4, zero(L_res)=4,lblpos(L_res)=75,lblPos(left)=75

ModifyGraph/W=FactorIonTS#FactorIonTS_plot grid(bottom)=2,tick(bottom)=1,gridRGB(bottom)=(0,0,0)

// separating line
SetdrawLayer UserBack
SetdrawEnv linethick=2.5
Drawline 0,0.3,1,0.3

// check data type of xwave
String XlabelStr="time"
IF (xwave[0]<3e8)
	XlabelStr="data index"
ENDIF

Label/W=FactorIonTS#FactorIonTS_plot bottom XlabelStr

// name for display, num2str makes only 5 significant digits -> not enough for LTOF increase to 10 digits
Make/O/T/N=(numpnts(sliderWave)) Names4display=""
Names4display=num2str(sliderWave[p])

Variable ii
String MZ_str,MZ_Str1
Variable beforedec,afterDec

FOR (ii=0;ii<numpnts(sliderWave);ii+=1)
	sprintf MZ_str1,"%.10f", sliderWave[ii]
	
	beforeDec=Strlen(Stringfromlist(0,MZ_str1,"."))	// digits before decimal point
	
	// remove trailing 0
	Variable ct=0

	DO
		MZ_str1=removeending(MZ_str1,"0")
		ct+=1		
	WHILE (ct<9)	// 

	afterDec=Strlen(Stringfromlist(1,MZ_str1,"."))	// digits after decimal point

	sprintf MZ_str,"%*.*f" beforedec,afterDec, sliderWave[ii]
	Names4display[ii]=MZ_str
ENDFOR

Make/O/T/N=(numpnts(labelWave)) Labels4display=""
Labels4display+=(labelWave[p])

LegendStr=removeEnding(LegendStr, "\r")
Legend/W=FactorIonTS#FactorIonTS_plot/A=RT/X=5.15/Y=31.75 LegendStr

//---------------------------------
// add table with ion masses and names
// display
Edit/HOST=FactorIonTS/N=FactorIonTS_info/W=(700,60,1000,700) sliderWave,Labels4display

// make it pretty
Modifytable/W=FactorIonTS#FactorIonTS_info showParts=0xfe, trailingZeros=1,size=14
ModifyTable/W=FactorIonTS#FactorIonTS_info format(Point)=1,width(Point)=40
Modifytable/W=FactorIonTS#FactorIonTS_info sigdigits(sliderWave)=8,width(sliderWave)=90
Modifytable/W=FactorIonTS#FactorIonTS_info width(Labels4display)=100

//---------------------------------
//slider and button
Variable/G sliderSet_ion=0
Variable/G sliderMax_ion=numpnts(SliderWave)-1
Variable/G Set_solution=Wavemin(p_map)
Variable/G Set_fpeak=0

Variable fpeakSteps=0
IF (numpnts(fpeak_map)>1)
	fpeakSteps=fpeak_map[1]-fpeak_Map[0]
ENDIF

String/G Label4Display_STR = Labels4display[sliderSet_ion]	// store current Label in Global String

//ControlBar/W=FactorIonTS 50
Slider  sliderMatrix Win=FactorIonTS,size={300,55},vert=0,ticks=4, limits={0,(SliderMax_ion),1},variable=SliderSet_ion,fsize=14,proc=MPaux_FIT_Slider_ion 

TitleBox SelectedFolder Win=FactorIonTS, title=folderPath,pos={600,5},size={200,20},fstyle=1,fsize=14,frame=0

SetVariable SetTrace Win=FactorIonTS, title="selected Ion mass",pos={328,3},size={200,20},value= Names4display[sliderSet_ion],noedit=1, fsize=14,noproc
SetVariable SetTraceChemLabel Win=FactorIonTS, title="Ion Label",pos={415,30},size={165,20},value=Label4Display_STR, fsize=14,proc=MPaux_FIT_IonLabelChange
SetVariable SetTraceNo Win=FactorIonTS, title="No.",pos={328,30},size={85,20}, limits={0,(SliderMax_ion),1},value= SliderSet_ion,fsize=14, proc=MPaux_FIT_SliderButton

SetVariable SetSolutionNo Win=FactorIonTS, title="solution",pos={600,30},size={90,20}, limits={Wavemin(p_map),Wavemax(p_map),1},value= Set_solution, fsize=14,proc=MPaux_FIT_SolutionSliderButton
SetVariable Setfpeak Win=FactorIonTS, title="fpeak/seed",pos={695,30},size={110,20}, limits={Wavemin(fpeak_map),Wavemax(fpeak_map),fpeakSteps},value= Set_fpeak, fsize=14,proc=MPaux_FIT_SolutionSliderButton

// reset Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)


END

//======================================================================================
//======================================================================================

// Purpose:		handle closing of window -> delete associated waves

// Input:			change from slider
// Output:		kills window, deletes waves in root:app:FactorIonTS and deltes that folder
// called by:	MPaux_FactorIonTS_Main() 	

FUNCTION MPaux_FIT_Hook(dataStruct)

STRUCT WMWinHookStruct &dataStruct

Variable HookResult=0

SWITCH (dataStruct.eventCode)
	CASE 2:	// window is killed
		
		// Killwindow does not release waves -> data cannot be deleted
		
		// get names of subwindows
		String subwindow_plot="FactorIonTS#FactorIonTS_plot"
		String subwindow_table="FactorIonTS#FactorIonTS_info"
		
		//-> loop through traces and remove
		String Alltraces=TracenameList(subwindow_plot,";",1)
		Variable ii
		FOR (ii=Itemsinlist(AllTraces)-1; ii>-1;ii-=1)	// start with last becasue tracenames can change
			removefromgraph/W=$subwindow_plot/Z $(Stringfromlist(ii,Alltraces))
		ENDFOR
			
		// remove labes4display from table (exact ion mass is located in PMF data folder)
		Wave/T labels4display=root:app:FactorIonTS:labels4display
		removefromTable/W=$subwindow_table/Z labels4display
		
		Killwindow/Z FactorIonTS
		killdatafolder/Z root:APP:FactorIonTS
		
		BREAK
		
ENDSWITCH

RETURN hookResult

END
//======================================================================================
//======================================================================================

// Purpose:		handle change from slider for FITS Panel

// Input:			change from slider
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() 	

Function MPaux_FIT_Slider_ion(name,value,event)	: sliderControl

String name	// name of this slider control
Variable value	// value of slider
Variable event	// bit field: bit 0: value set; 1: mouse down, //   2: mouse up, 3: mouse moved

IF(event&1)
	MPaux_FIT_Ion_Changed(value)
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		handle change from ion number for FITS Panel	

// Input:			change from variable
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() 	

Function MPaux_FIT_SliderButton(ctrlName,varNum,varStr,varName) : SetVariableControl

String ctrlName
Variable varNum
String varStr
String varName

ControlInfo /W=FactorIonTS SetTraceNo

MPaux_FIT_Ion_Changed(V_value)

END

//======================================================================================
//======================================================================================

// Purpose:		handle change of ion label for FITS Panel

// Input:			change from slider
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() 	

FUNCTION MPaux_FIT_IonLabelChange(CtrlName,varNum,varStr,varName) : SetVariableControl

String ctrlname
Variable varNum
String varStr
String varName

String alertStr=""

// get waves with labels linked to panel
Wave/T Labels4display=root:APP:FactorIonTS:Labels4display

// get new label
SVAR Label4Display_STR=root:app:FactorIonTS:Label4Display_STR

// get previous label (using numeric value)
ControlInfo /W=FactorIonTS SetTraceNo
String oldLabel=Labels4display[V_value]

// look for new name in wave
Extract/FREE/INDX Labels4display,foundLabel, stringmatch(Labels4display,Label4Display_STR)

// no entry found:
IF (numpnts(foundLabel)==0)
	// use previous and alert user
	alertStr="The following ion was not found in the ion name list:\r\r"+Label4Display_STR
	
	Label4Display_STR=oldLabel
	
	MPaux_abort(alertStr)
ENDIF

// more than one found
IF (numpnts(foundLabel)>1)
	
	alertStr="The following ion was found multiple times in the ion list wave:\r\r"+Label4Display_STR
	alertStr+="\r\r check the history for row indices and check the table in the FITS panel."

	print "------------------------"
	print date() + " "+ time() +": changing FITS Panel ion by providing ion name"
	print "multiple entries found for ion: "+ Label4Display_STR
	print foundLabel
	
	Label4Display_STR=oldLabel
	
	MPaux_abort(alertStr)
ENDIF

// change plot
MPaux_FIT_Ion_Changed(foundLabel[0])


END


//======================================================================================
//======================================================================================

// Purpose:		handle change from ion number for FITS 	

// Input:			change from variable
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() 	

Function MPaux_FIT_SolutionSliderButton(ctrlName,varNum,varStr,varName) : SetVariableControl

String ctrlName
Variable varNum
String varStr
String varName

SVAR abortStr=root:APP:abortStr

SVAR folderPath=root:APP:FactorIonTS:folderPath
Wave p_map=$(folderPath+":p_map")
Wave fpeak_map=$(folderPath+":fpeak_map")

ControlInfo /W=FactorIonTS SetSolutionNo
Findvalue/V=(V_value)/T=0.001 p_map	// change to FindValue to handle "wrong" values in a better way
Variable p_pos=V_Value
//Variable p_pos=binarysearch(p_map,V_value)	// value in control may not be same as index in wave

ControlInfo /W=FactorIonTS Setfpeak
Findvalue/V=(V_value)/T=0.001 fpeak_map
Variable fpeak_pos=V_Value
//Variable fpeak_pos=binarysearch(fpeak_map,V_value)

IF (fpeak_pos<0)
	print "----------------------"
	print date() + time() + " MPaux_FIT_SolutionSliderButton:"
	print "MPaux_FIT_SolutionSliderButton: set fpeak value not found."
	print "select a valid value for fpeak/seed:"
	print fpeak_map
	
	abortStr="MPaux_FIT_SolutionSliderButton:"
	abortStr+="\r\rfpeak/seed value not found\rcheck valid values from the history window."
	mpAUX_abort(abortStr)
ENDIF

IF (p_pos<0)
	print "----------------------"
	print date() + time() + " MPaux_FIT_SolutionSliderButton:"
	print "MPaux_FIT_SolutionSliderButton: set number of factors not found."
	print "select a valid values for fpeak/seednumber of factors:"
	print p_map
	
	abortStr= "MPaux_FIT_SolutionSliderButton:\r\rinvalid number of factors."
	abortStr+="\rsolution number must be an integer between "+num2str(Wavemin(p_map))+" and "+num2str(wavemax(p_map))
	mpAUX_abort(abortStr)
ENDIF

MPaux_FIT_Solution_Changed(P_pos,fpeak_pos)

END

//======================================================================================
//======================================================================================

// Purpose:		calculate data for differnt solution	

// Input:			value:		idx for current ion for plotting
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() -> MPaux_FIT_Slider_ion() or MPaux_FIT_FactorSliderButton()


FUNCTION MPaux_FIT_Solution_Changed(sol_Pos,fpeak_pos)

Variable sol_Pos
Variable fpeak_pos

Wave MSreconst_plot=root:APP:FactorIonTS:MSreconst_plot
Wave matrix_oneion=root:APP:FactorIonTS:matrix_oneion
Wave residual_data=root:APP:FactorIonTS:residual_data

Wave/T Names4display=root:APP:FactorIonTS:names4Display
Wave/T labels4Display=root:APP:FactorIonTS:labels4Display
Wave/T TraceNames_MS=root:APP:FactorIonTS:TraceNames_MS
Wave colourTable=root:APP:FactorIonTS:ColourTable

NVAR maxP=root:APP:FactorIonTS:maxP

SVAR folderPAth=root:APP:FactorIonTS:folderPath
SVAR MSdata_name=root:APP:FactorIonTS:MSdata_name

Wave MSdata=$MSdata_name

// recalculate data for plot
Wave Gmx4D=$(folderPath+":Gmx4D")
Wave Fmx4D=$(folderPath+":Fmx4D")

Variable ff

// calculate factor reconstructed mass spectra
FOR (ff=0;ff<maxP;ff+=1)
	// check first entry NaN -> set result to 0
	IF (numtype(Fmx4D[ff][0][fpeak_pos][sol_Pos])==0)
		MSreconst_plot[][][ff]=Gmx4D[p][ff][fpeak_pos][sol_Pos]*Fmx4D[ff][q][fpeak_pos][sol_Pos]
	ELSE
		// no entry
		MSreconst_plot[][][ff]=0
	ENDIF
	
ENDFOR	// factor loop

ControlInfo /W=FactorIonTS SetTraceNo

matrix_oneion=MSreconst_plot[p][V_value][q]

// get residual
Sumdimension/D=2/Dest=temp_sum MSreconst_plot
residual_data=MSdata-temp_sum
Killwaves/Z temp_Sum

END


//======================================================================================
//======================================================================================

// Purpose:		change the displayed ion in FITS plot	

// Input:			value:		idx for curernt ion for plotting
// Output:		changed plot
// called by:	MPaux_FactorIonTS_Main() -> MPaux_FIT_Slider_ion() or MPaux_FIT_FactorSliderButton()


FUNCTION MPaux_FIT_ion_Changed(value)

Variable Value

Wave matrix_oneion=root:APP:FactorIonTS:matrix_oneion
Wave MSreconst_plot=root:APP:FactorIonTS:MSreconst_plot
Wave residual_data=root:APP:FactorIonTS:residual_data

Wave/T Names4display=root:APP:FactorIonTS:names4Display
Wave/T labels4Display=root:APP:FactorIonTS:labels4Display
Wave/T TraceNames_MS=root:APP:FactorIonTS:TraceNames_MS

NVAR maxP=root:APP:FactorIonTS:maxP
NVAR sliderSet_ion=root:APP:FactorIonTS:sliderSet_ion

SVAR MSdata_name=root:APP:FactorIonTS:MSdata_name
SVAR Label4Display_STR =root:APP:FactorIonTS:Label4Display_STR

Variable ff

matrix_oneion=MSreconst_plot[p][value][q]

// change MS data
replaceWave/W=FactorIonTS#FactorIonTS_plot trace=$TraceNames_MS[maxP] $MSdata_name[][value]

// change residual data
replaceWave/W=FactorIonTS#FactorIonTS_plot trace=$TraceNames_MS[maxP+1] residual_data[][value]

//adjust displayed ion id
SetVariable SetTrace,Win=FactorIonTS,value=Names4display[value]	// exact mz
Label4Display_STR=Labels4display[value]	// ion name
sliderSet_ion=value	// ion number field and slider position

END

//======================================================================================
//======================================================================================

// Purpose:		transfer selected wave names upon closing of PET prep window

// Input:			datastructure with info about event
// Output:		kills window and copies wavenmaes into MaSPET
// called by:	CLosing of PMF_PerformCalc_Panel Window

FUNCTION MPaux_PETprep_hook(dataStruct)

STRUCT WMWinHookStruct &dataStruct

Variable HookResult=0

SWITCH (dataStruct.eventCode)
	CASE 2:	// window is killed
		
		// transfer Wavenames to MaSPET panel using "_last" Strings
		svar DataMxNm = $("root:pmf_calc_globals:DataMxNm")
		svar StdDevMxNm = $("root:pmf_calc_globals:StdDevMxNm")
		svar ColDescrWvNm = $("root:pmf_calc_globals:ColDescrWvNm")
		//svar ColDescrTxtWvNm = $("root:pmf_calc_globals:ColDescrTxtWvNm")
		svar ColDesTxtWvNm = $("root:pmf_calc_globals:ColDesTxtWvNm")	// added for PET >3.07
		svar RowDescrWvNm = $("root:pmf_calc_globals:RowDescrWvNm")
		
		// put wavenames into Wavenames Wave 
		// do nothing if the field was empty (to catch if no folder was found and fields in PET are empty)
		Wave/T Wavenames=root:APP:datawavenames
		IF (!stringmatch(DataMxNm,""))
			wavenames[%MSdataName]=DataMxNm
		ENDIF
		IF (!stringmatch(StdDevMxNm,""))
			wavenames[%MSerrName]=StdDevMxNm
		ENDIF
		IF (!stringmatch(ColDescrWvNm,""))
			wavenames[%MZname]=ColDescrWvNm
		ENDIF
		IF (!stringmatch(ColDesTxtWvNm,""))
			wavenames[%LAbelName]=ColDesTxtWvNm
		ENDIF
		IF (!stringmatch(RowDescrWvNm,""))
			wavenames[%Tname]=RowDescrWvNm
		ENDIF
		// kill window
		Killwindow/Z PMF_PerformCalc_Panel
		BREAK
		
ENDSWITCH

RETURN hookResult

END

