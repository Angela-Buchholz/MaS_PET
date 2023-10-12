#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		

//======================================================================================
//	MaS_PET_plotting contains the plotting functions for MaS-PET. 
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

// Use modern global access method and strict wave access.

// Purpose:	use data extracted with getFactors() and create plots with profiles and mas specs
//				designed to run with APP but also works standalone from command line
//				for standalone: you can use "order" wave to plot only a subset of factors
/
// Input:		PMF factor data must have been extracted with getSolution()
//				typical input
//				folderStr:	name of Folder with PMF results (full name, root:PMFresults can be skipped)
//				nSol:			number of factors (solution)
//				expListName: Wave with names for samples (eg lowOC_00RTC)
//				Wavenames:	Wave with names of data waves
//				[order]:		Wave with factor numbers for plotting
//								use this to change the plotting order or to plot a subset of factors
// 				[unitStr]:	String to use for the y axis label
//
// Output:	plots according to selection

//======================================================================================
//======================================================================================

// plot simple time series, samples not split
 
FUNCTION MPplot_plotPMFtseries(folderStr,nsol,Wavenames[,order,unitStr])

String FolderStr
Variable nSol
Wave/T Wavenames
Wave order
String unitStr

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	folderPath= replaceString("root:root:",folderPath,"root:")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFtseries():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check if factor MS and time seires waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFtseries():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPplot_plotPMFtseries():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

// check optional parameters
// different order for factors
IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE
	Wave FactorOrder=order
ENDIF

// y axis label String
IF (paramisdefault(unitStr))
	unitStr="ct s\\S-1"
ENDIF

Variable nop=numpnts(factorOrder)

//------------------------------

// make 'time' series plot
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

String graphname=MPplot_MakeGraphName("tseries_",folderStr1,"")

Killwindow/Z $graphname	// Igor 7 introduced Z flag
Display/W=(50,50,550,600) as graphname
Dowindow/C $graphname

Variable ff=0
Variable IDidx
String currentYstr, traceList,currentTrace
String legendStr=""

FOR (ff=0;ff<numpnts(FactorOrder);ff+=1)
	//	get non default order of factors
	IDidx=FactorOrder[ff]
	
	currentYstr="Factor_TS"+num2str(IDidx)
	Wave ywave=$currentYstr
	Wave xwave=$Wavenames[%Tname]
	
	// check if wave exists
	IF (Waveexists(xwave) && waveexists(ywave))
		// do plot
		appendtograph ywave vs xwave
		traceList=Tracenamelist("",";",1)
		currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
		
		// legend and colour
		legendstr+="\\s(" +currentTrace+ ") Factor " +num2str(IDidx) +"\r"
		
		Variable ColourIdx=ff
		// catch if single factor is plotted
		IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
			ColourIdx=FactorOrder[0]-1
		ENDIF

		colourIDX-=floor(ff/22)*dimsize(colourwave,0)
		
		ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
	ELSE
		abortStr="MPplot_plotPMFtseries():\r\rcannot find wave: "+currentYstr+ " or "+ Wavenames[%Tname]
		abortStr+= " in folder "+ folderPath
		MPaux_abort(AbortStr)
	ENDIF
ENDFOR

// axis
SetAxis left 0,*
SetAxis bottom *,*
ModifyGraph tick(left)=2,mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,notation=1
Modifygraph mirror(bottom)=2,notation=1

// check data type of xwave
String XlabelStr="time"
IF (xwave[0]<3e8)	// for xwave with other than time data
	XlabelStr="data index"
	SetAxis bottom 0,*
ELSE
	// set wavesclaing to make xaxis proper time
	SetScale d 0,0, "dat" , xwave
ENDIF
Label bottom XlabelStr
Label left "signal / "+unitStr

// legend
legendStr=removeending(legendStr, "\r")
Legend/C/N=Leg1/A=RT legendStr

// traces
ModifyGraph lsize=2

// clean up
Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot timseries for each experiment

FUNCTION MPplot_plotPMFtseriesSplit(folderStr,nsol,ExpListName[,order,Single,PanelNumber,unitStr])

String FolderStr	// complete folder name (eg combi_F9)
String ExpListName 	// wave name for textwave in root: withnames of scans (eg. med00_RTC)
Variable nsol
Variable single
Wave order
Variable PanelNumber
String unitStr

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root: to folderpath
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFtseriesSplit():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// look for explist wave
Wave/T ExpList=$ExpListName
IF (!Waveexists(ExpList))
	abortStr="MPplot_plotPMFtseriesSplit():\r\rNo Wave with name "+ ExpListName+" found in root folder"
			
	MPaux_abort(AbortStr)
ENDIF

// check for waves
Variable WaveCheck=MPaux_check4FitPET_bysample(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFtseriesSplit:\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for data split into samples:"
	print "\t\tfactor time series:\t'NameOfSample_Thermos' (or 'NameOfSample_TS' in DataSortedBySample subfolder)"
 	print "\t\tfactor Tmax series:\t'NameOfSample_Tmax"
 	print "\t\tfactor contribution:\t'NameOfSample_Farea"

	// abort
	abortSTr="MPplot_plotPMFtseriesSplit:\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)

ENDIF

// check if sample data was sorted into subfolder
String SubFolderPath=folderPath
IF (datafolderexists(folderPath+":DataSortedBySample"))
	SubFolderPath+=":DataSortedBySample"
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

// go to results folder
setdatafolder $folderPath

// check optional parameters
IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE
	Wave FactorOrder=order
	
ENDIF

Variable nof=numpnts(factorOrder)

// warning for high number of samples
String alertStr=""
IF (numpnts(expList)>25)
	alertStr="WARNING: There are "+num2str(numpnts(expList))+" samples in your data set. \rContinue plotting?"
	DoALert 1, alertStr
	IF (V_flag==2)
		abort
	ENDIF
ENDIF

// set up values for multi column drawing
IF(Paramisdefault(panelNumber))
	panelNumber=numpnts(expList)
ENDIF

IF (panelNumber>numpnts(expList))	// catch if les factors/samples than maximum
	panelnumber=numpnts(expList)
ENDIF

Variable noc=ceil(numpnts(expList)/panelNumber)	//number of columns

// y axis label String
IF (paramisdefault(unitStr))
	unitStr="ct s\\S-1"
ENDIF

//---------------------

setdatafolder $SubfolderPath	// this catches if sample waves are in subfolder (from v1.8 onward)

Variable ff=0,ee=00,ct=1
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

IF (!paramisdefault(Single))	// check if single sample was plotted and add to name
	folderStr1+="_"+num2str(Single)
ENDIF

String graphname=MPplot_MakeGraphName("SampleTseries_",folderStr1,"")

// set plot width
Variable plotWidth=1000
IF (noc==1)
	plotWidth=500
ENDIF	

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable space=0.08				// extra space between volumns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(numpnts(explist))+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// prepare Graph window
killwindow/Z $graphname
Display/W=(50,50,plotWidth,600) as graphname
Dowindow/C $graphname

String currentYstr=""
String currentXstr=""
String TraceName=""
String LegendStr=""
Variable IDidx

FOR (ee=0;ee<numpnts(expList);ee+=1)

	// define drawing parameters
	Variable CurrentCol=floor(ee/panelNumber)	// current column
	
	String XAxisName="B"+num2Str(CurrentCol)
	
	Variable DrawStart=1-(ee+1)*1/panelNumber	+ CurrentCol		// Start Panel in each coloumn
	Variable DrawEnd=1-(ee)*1/panelNumber + CurrentCol	// End panel in each coloumn
	Variable lastgrid=1
	
		//handle last column
	IF(MOD(numpnts(expList),panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(numpnts(expList),panelNumber)	// how many panels in last column will be empty
		// adjust the axis draw value
		DrawStart=1-(ee+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ee+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(numpnts(expList),panelNumber))*1/panelNumber
	ENDIF

	
	Variable DrawBottomStart= CurrentCol*Drawinterval	// bottom axis start
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval	//bottom axis end

//	IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
//	ENDIF	
	DrawBottomEnd-=space/2
	
	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+2
	Variable LegYPos=100-100*DrawEnd+2

	FOR (ff=0;ff<nof;ff+=1)
		// get factor ID number		
		IDidx=	FactorOrder[ff]
		
		String YaxisName="L"+num2str(ee)
		currentYstr=explist[ee]+"_TS"
		
		Wave ywave=$currentYstr
		Wave xwave=$currentYstr	// temperature is in first column
	
		IF (Waveexists(xwave) && waveexists(ywave))
			// draw trace
			appendtograph/L=$YaxisName/B=$XAxisName ywave[][IDidx] vs xwave[][0]
			
			TraceName=Tracenamelist("",";",1)
			TraceName=Stringfromlist(Itemsinlist(TraceName)-1,TraceName)
		
			// legend and colour
			IF (ee==0)
				legendstr+="\\s(" +TraceName+ ") Factor " +num2str(IDidx) +"\r"
			ENDIF
			IF (IDidx>dimsize(colourwave,0))
				IDidx-=ct*dimsize(colourwave,0)
				ct+=1
			ENDIF
			
			ModifyGraph rgb($TraceName)=(colourwave[IDidx-1][0],colourwave[IDidx-1][1],colourwave[IDidx-1][2])
		ELSE
			abortStr="MPplot_plotPMFtseriesSplit():\r\rcannot find wave: "+currentYstr
			abortStr+= " in folder "+ folderPath
			MPaux_abort(AbortStr)
		ENDIF

	ENDFOR	// factor loop

		// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd},mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)

	// set panel Label
	String TextStr="\\Z16 "+ExpList[ee]
	
	TextBox/C/N=$("text"+num2str(ee+1))/F=0/B=1/A=RT/X=(LegXPos)/Y=(LegYpos) textStr	

ENDFOR	// experiment folder loop

// make graph pretty
ModifyGraph lsize=2

ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,notation=1,lblPos=70,lblLatPos=0,Tick=2,nticks=3,notation=1

Label L0 "signal / "+unitStr

// add title label
String titleStr=""
titleStr+=  "\\Z16\\f01"+folderStr1
TextBox/C/N=text0/F=0/A=MT/X=12/Y=3 titleStr

// add legend
legendStr=removeending(legendStr, "\r")
Legend/C/N=Leg1/A=RT legendStr

ShowTools/A
ShowInfo

//coloured boxes for Volatility ranges

// check for calibration data and recalcualte VOlatility classes
Wave/Z TmaxCstarCal_values=TmaxCstarCal_values
Variable vv
		
IF(Waveexists(TmaxCstarCal_values) && (TmaxCstarCal_values[0]!=0 && TmaxCstarCal_values[1]!=0))	// 
	// adjust drawing layer
	SetDrawLayer UserBack
	
	// calculate borders
	Make/FREE/D/N=400 T_dummy=(p+1)*0.5,Psat_dummy,logCstar_dummy
	
	psat_dummy=exp(TmaxCstarCal_values[0]+T_dummy[p]*TmaxCstarCal_values[1])
	logCstar_dummy=log(psat_dummy*200/8.314/298*1e6)
	Make/D/O/N=(4,2) VOCRanges=NaN
	note VOCRanges, "Tmax values for:SVOC;LVOC;ELVOC;ULVOC"
	
	Make/FREE/D/N=(5) dummy={2.5,-0.5,-4.5,-8.5,-15}	// ranges for SVOC to ULVOC from Schervish et al ACP 2020
	
	Make/FREE/D/N=(4,3) colour_dummy
	colour_dummy[][0]={26205,65535,30583,29524}
	colour_dummy[][1]={52428,32768,30583,1}
	colour_dummy[][2]={1,32768,30583,58982}
	
	FOR (vv=0;vv<dimsize(VOCRanges,0);vv+=1)	// loop through classes
		// get the range for each Volatility Class
		Extract/INDX/FREE logCstar_dummy,IDXwave,logCstar_dummy<=dummy[vv] && logCstar_dummy>=dummy[vv+1]
		
		IF (numpnts(IDXwave)>0)
			VOCRanges[vv][0]=T_dummy[IDXwave[0]]
			VOCRanges[vv][1]=T_dummy[IDXwave[numpnts(IDXWave)-1]]
			
			// catch if values are outside of 20-210 C
			IF (VOCRanges[vv][0]<20)
				VOCRanges[vv][0]=20
			ENDIF
			IF (VOCRanges[vv][1]>210)
				VOCRanges[vv][1]=210
			ENDIF
			
			//draw boxes
			// lower box
			SetDrawEnv xcoord= bottom,ycoord= prel,linefgc= (26205,52428,1),fillpat= 4,fillfgc= (colour_dummy[vv][0],colour_dummy[vv][1],colour_dummy[vv][2]),linethick= 0.00
			DrawRect VOCRanges[vv][0],0,VOCRanges[vv][1],0.04
			// upper box
			SetDrawEnv xcoord= bottom,ycoord= prel,linefgc= (26205,52428,1),fillpat= 4,fillfgc= (colour_dummy[vv][0],colour_dummy[vv][1],colour_dummy[vv][2]),linethick= 0.00
			DrawRect VOCRanges[vv][0],1,VOCRanges[vv][1],1.07

		ELSE
			// set indicator that out of range
			VOCRanges[vv][0]=-1
			VOCRanges[vv][1]=-1
		ENDIF
		
	ENDFOR
	
	// reset drawing layer
	SetDrawLayer UserFront
	
ENDIF

// handle multiple x axis
String bottomName=""
Variable ii

String Xlabel="time"
Variable Xmin=0
Variable Xmax=0
Variable TickMain=0
Variable TickMinor=0

// catch Figaero vs other
IF (xwave[0]<3e8)	// for xwave with other than time data
	Xlabel="desorption T / °C"
	Xmin=0
	Xmax=210
	TickMain=50
	TickMinor=4
ENDIF

FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname Xlabel
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction}
	
	IF (Xmin==0 && Xmax==0)
		// for everything
		SetAxis $Bottomname *,*
		
	ELSE
	//	for FIGAERO thermograms
		SetAxis $Bottomname Xmin,Xmax
		
		ModifyGraph minor($Bottomname)=0,manTick($Bottomname)={0,TickMain,0,0},manMinor($Bottomname)={Tickminor,0}
	ENDIF
ENDFOR

// set mirror axis position for last column
Modifygraph mirrorPos($BottomName)=lastGrid,gridenab($BottomName)={0,lastGrid}

// clean up	
SetDrawLayer UserFront

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot factor spectra

FUNCTION MPplot_plotPMFms(folderStr,nSol,Wavenames,[panelNumber,order,threshold])

String FolderStr
Variable nSol
Wave/T Wavenames
Variable Panelnumber	// number of Panels in each column
Variable threshold
Wave order

// check optional parameters
// threshold for plotting
IF (paramIsDefault(threshold))
	threshold=0.0001
ENDIF
IF (threshold==0)	// catch 0
	threshold=1e-6
ENDIF

IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE
	Wave FactorOrder=order
	
ENDIF

Variable nof=numpnts(factorOrder)

IF(Paramisdefault(panelNumber))
	panelNumber=nof
ENDIF

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns
	
//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFms():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check if factor MS and time seires waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFms():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	abortSTr="MPplot_plotPMFms():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	 
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

// make factor mass spec plot
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

// catch if single factor is plotted
String suffix=""
IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
	suffix="_Fac"+num2Str(FactorOrder[0])
ENDIF

String graphname=MPplot_MakeGraphName("factorMS_",folderStr1,suffix)

// make axis draw range
Variable plotWidth=1000
IF (noc==1)
	plotWidth =500
ENDIF
	
Make/FREE/D/O/N=(nof,2) YaxisDraw,XaxisDraw

// get other waves
Wave OCfactor
Wave OScfactor
Wave/T Compfactor

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.06				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(numpnts(factorOrder))+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// prepare window

Killwindow/Z $graphname	// Igor 7 introduced Z flag
Display/W=(50,50,plotWidth,600) as graphname
Dowindow/C $graphname

Variable ff=0,IDidx
String currentYstr, traceList,currentTrace,CurrentAxis
String textStr="\\Z14"

// do plotting
FOR (ff=0;ff<numpnts(FactorOrder);ff+=1)
	
	IDidx=FactorOrder[ff]	// number of current factor 
			
	currentYstr="factor_MS"+num2str(IDidx)
	Wave ywave=$currentYstr
	Wave xwave=$Wavenames[%MZname]
	
	// define draw values
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// Start Panel in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// End panel in each coloumn
	Variable lastgrid=1
	
		//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF

	Variable DrawBottomStart= CurrentCol*Drawinterval	// bottom axis start
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval	//bottom axis end

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=Space/2
	//ENDIF
	DrawBottomEnd-=Space/2	

	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+1
	Variable LegYPos=100-100*DrawEnd
	
	//do the plotting
	IF (Waveexists(xwave) && waveexists(ywave) )
		// plot
		appendtograph/L=$(YAxisName)/B=$(XAxisName) ywave vs xwave

		//tracenames
		traceList=Tracenamelist("",";",1)
		currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
		
		// colour and legendstring
		textStr+="Factor " +num2str(IDidx) +" "
		IF (waveexists(CompFactor))
			textStr+=CompFactor[IDidx-1]+"\r"
			textStr+="\tOC: "+num2str(round(OCfactor[IDidx-1]*100)/100) +" OSc: "+num2str(round(OScfactor[IDidx-1]*100)/100) 
		ENDIF

		TextBox/C/B=1/N=$("Leg"+num2str(IDidx))/A=RT/Y=(LegYPos)/X=(LegXpos) textStr

		Variable ColourIdx=ff
		// catch if single factor is plotted
		IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
			ColourIdx=FactorOrder[0]-1
		ENDIF

		colourIDX-=floor(ff/22)*dimsize(colourwave,0)	// catch more than 22 factors
		
		//ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
		ModifyGraph zcolor($CUrrentTrace)={yWave,threshold,threshold*1.0001,rainbow,0},zcolorMax($CUrrentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2]),zcolorMin($CUrrentTrace)=NaN
	
		// set axis properties
		ModifyGraph axisEnab($YAxisName)={DrawStart,DrawEnd}, tick($YAxisName)=2,nticks($YAxisName)=2
		SetAxis $YAxisName 0,*
		ModifyGraph mirrorPos($YAxisName)=DrawMirror
		
		// axis draw
		Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
		ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd}
		ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd},mirror($XAxisName)=2

		// devision lines for panels
		SetDrawLayer UserBack
		SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
		DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)
		
		//reset legendStr
		textStr="\\Z14"
	ELSE
		abortStr="MPplot_plotPMFms():\r\rcannot find wave: "+currentYstr+ " or "+ Wavenames[%MZname]
		abortStr+= " in folder "+ folderPath
		MPaux_abort(AbortStr)
	
	ENDIF
	
ENDFOR

// axis
ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,notation=1,lblPos=70,lblLatPos=0,lowTrip=0.001,notation=1
Label L0 "normalised signal"

// handle multiple x axis
String bottomName=""
Variable ii
FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname "m/z / amu"

	SetAxis $Bottomname 0,*
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction},mirror($Bottomname)=2
	
ENDFOR

//grid lines for last column
Modifygraph mirrorPos($BottomName)=lastGrid

SetDrawLayer UserFront

// traces
ModifyGraph mode=1,lsize=2

// clean up
Setdatafolder $oldFolder

END


//======================================================================================
//======================================================================================

// plot factor spectra as bubble plot

FUNCTION MPplot_plotPMFmsGrid(folderStr,nSol,[panelNumber,order,threshold])

String FolderStr			// data folder with solution
Variable nSol			// number of factors in solution
Variable panelNumber	// panels per column
Variable Threshold		// minimum value to use
Wave order				// factor order

setdatafolder root:

// check optional parameters
IF (paramIsDefault(threshold))
	// default value
	threshold=0.001
ENDIF
IF (threshold==0)	// catch 0
	threshold=1e-6
ENDIF

IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE

	Wave FactorOrder=order
	
ENDIF

Variable nof=numpnts(FactorOrder)	// number of factors

IF (Paramisdefault(PanelNumber))		// number of panels per column
	PanelNumber=nof
ENDIF

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns
variable Lastgrid=1	// height of grid in last column

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFmsGrid():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check if factor MS and time seires waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFmsGrid():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	abortSTr="MPplot_plotPMFmsGrid():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	 
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

// get stuff set for plotting
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

// catch if single factor is plotted
String suffix=""
IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
	suffix="_Fac"+num2Str(FactorOrder[0])
ENDIF

String graphname=MPplot_MakeGraphName("factorGrid_",folderStr1,suffix)

// make axis draw range
Variable plotWidth=1000
IF (noc==1)
	plotWidth =500
ENDIF

// get other waves
Wave OCfactor
Wave OScfactor
Wave/T Compfactor

Wave ElementNum			// getfactors() should have created these Waves (issue if length changes)
Wave/D OSc_ions

IF (!Waveexists(ElementNum))	// check tha these waves exist
	abortStr= "MPplot_plotPMFmsGrid():\r\rWave 'ElementNum' not found in PMF results folder:\r"+FolderPath
	MPaux_abort(AbortStr)
ENDIF
IF (!Waveexists(OSc_ions) && Waveexists(ElementNum))	// calculate OSc_ions if element numbers are there
	
	Make/D/O/N=(dimsize(ElementNum,0)) OSc_ions
	Wave/D OSc_ions=OSc_ions
	
	OSc_ions= 2*ElementNum[p][2]/ElementNum[p][0] - ElementNum[p][1]/ElementNum[p][0]
	
ENDIF

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.03				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(nof)+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// prepare window
Killwindow/Z $graphname	// Igor 7 introduced Z flag
Display/W=(50,20,plotWidth,600) as graphName
Dowindow/C $graphname

// prepare containers for grid plotting waves
Newdatafolder/S/O MSgridPlot
Make/FREE/D/N=(dimsize(elementNUm,0)) Cnum=ElementNUm[p][0]

Make/O/D/N=(WaveMAx(Cnum)) Cnum_grid=p-0.5	// center around full integer values using cnum in data
Make/O/D/N=(5/0.2) OSC_grid=(p*0.2)-2		// from -2 - +3 in 0.2 steps


// loop through factors
Variable ff,IDidx,ii,kk
String currentZstr, traceList,currentTrace,CurrentAxis,currentFactorStr
String textStr="\\Z14"

FOR (ff=0;ff<nof;ff+=1)
	//---------------------------------	
	IDidx=FactorOrder[ff]	// number of current factor 

	// calculate grid values
	currentZstr="factor_MS"+num2str(IDidx)+"_grid"
	currentFactorstr="::factor_MS"+num2str(IDidx)
	
	Wave CurrentFactor=$currentFactorstr
	
	Make/D/O/N=(numpnts(Cnum_grid)-1,numpnts(OSc_grid)-1) $currentZstr
	Wave Grid=$currentZstr
	Grid=NaN
	
	FOR(ii=0;ii<Dimsize(Grid,0)-1;ii+=1)	// loop through C number
		// extract 1 C number
		Extract/FREE CurrentFactor,temp_Cnum,elementNum[p][0]>Cnum_grid[ii] && elementNum[p][0]<Cnum_grid[ii+1]
		Extract/FREE OSc_ions,temp_OSC,elementNum[p][0]>Cnum_grid[ii] && elementNum[p][0]<Cnum_grid[ii+1]
		
		IF (numpnts(temp_Cnum)>0)
			// loop through OSC
			FOR(kk=1;kk<Dimsize(Grid,1)-2;kk+=1)	// loop through OSC
				Extract/FREE temp_Cnum,temp_dest,temp_OSC >OSc_grid[kk] && temp_OSC <=OSc_grid[kk+1]
				IF (numpnts(temp_dest)>0)
					Grid[ii][kk]=sum(temp_dest)
				ENDIF
			ENDFOR	// OSC loop
			
			// first one has everything smaller
			Extract/FREE temp_Cnum,temp_dest,temp_OSC <=OSc_grid[1]
			IF (numpnts(temp_dest)>0)
				Grid[ii][0]=sum(temp_dest)
			ENDIF
			
			// last everything larger
			Extract/FREE temp_Cnum,temp_dest,temp_OSC >OSc_grid[numpnts(OSc_grid)-2]
			IF (numpnts(temp_dest)>0)
				Grid[ii][Dimsize(Grid,1)-1]=sum(temp_dest)
			ENDIF
		ENDIF
	ENDFOR	// Cnum loop
	
	//---------------------------------
	// define draw values
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// panels in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// panels in each coloumn

	LastGrid=1

	//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF
		
	Variable DrawBottomStart= CurrentCol*Drawinterval
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF
	DrawBottomEnd-=space/2
	
	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+1
	Variable LegYPos=100-100*DrawEnd

	//---------------------------------
	// do plot

	AppendImage/L=$YAxisName/B=$(XaxisName) Grid vs {Cnum_grid,OSc_grid}
	
	// appearance
	traceList=Imagenamelist("",";")
	currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
	
	ModifyImage $currentTrace ctab= {threshold,0.05,Rainbow256,1},minRGB=NaN,maxRGB=0
	ModifyImage $currentTrace log=1  //color code in log scale
	SetAxis $YAxisName *,3.5
	
	// legendstring
	textStr+="Factor " +num2str(IDidx) +" "
	IF (waveexists(CompFactor))
		textStr+=CompFactor[IDidx-1]+"\r"
		textStr+="\tOC: "+num2str(round(OCfactor[IDidx-1]*100)/100) +" OSc: "+num2str(round(OScfactor[IDidx-1]*100)/100) 
	ENDIF
	
	TextBox/C/B=1/N=$("Leg"+num2str(IDidx))/A=RT/Y=(LegYPos)/X=(LegXpos) textStr
	
	// set axis properties
	ModifyGraph axisEnab($YAxisName)={DrawStart,DrawEnd}, tick($YAxisName)=2,nticks($YAxisName)=2
	SetAxis $YAxisName -1.9,2.9
	
	ModifyGraph mirrorPos($YAxisName)=DrawMirror
	
	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd},gridEnab($YAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)
	
	//reset legendStr
	textStr="\\Z14"
ENDFOR

ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,notation=1,lblPos=70,lblLatPos=0

Label L0 "OSc"

// handle multiple x axis
String bottomName=""

FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname "number of C"

	SetAxis $Bottomname 0,*
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction},mirror($Bottomname)=2
	
	ModifyGraph minor($Bottomname)=1,sep($Bottomname)=20

ENDFOR

ColorScale/C/N=text0/F=0/A=MC vert=0,side=2,width=80,frame=2.00,image=$currentZstr,axisRange={0.001,0.05}
ColorScale/C/N=text0 fsize=14,fstyle=1,log=1,lblMargin=70,tickLen=6.00,tickThick=2.00
ColorScale/C/N=text0/A=RT/B=1/X=0.00/Y=5.00 "Log (Norm. Signal)"

ModifyGraph grid=1,mirror=2,axThick=2,gridHair=1,gridRGB=(48059,48059,48059), nticks=3

//grid lines for last column
Modifygraph gridEnab($BottomName)={0,lastgrid},mirrorPos($BottomName)=lastGrid

// clean up	
SetDrawLayer UserFront

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot factor spectra as bubble plot

FUNCTION MPplot_plotPMFmsBubble(folderStr,nSol,[panelNumber,order,threshold])

String FolderStr		// name of folder with data
Variable nSol		// number of factors in solution
Variable panelNumber	// panel per column
Variable threshold	// minimum htreshold for visible bubbles
Wave order			// factor order

setdatafolder root:

// check optional parameters
IF (paramIsDefault(threshold))
	// default value
	threshold=0.001
ENDIF
IF (threshold==0)	// catch 0
	threshold=1e-6
ENDIF

IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE
	Wave FactorOrder=order
ENDIF

Variable nof=numpnts(FactorOrder)	// number of factors in plot

IF (Paramisdefault(PanelNumber))		// number of panels per column
	PanelNumber=nof
ENDIF

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns
Variable Lastgrid=1

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFmsBubble():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check if factor MS and time series waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFmsBubble():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	abortSTr="MPplot_plotPMFmsBubble():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	 
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

// get stuff set for plotting
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

// catch if single factor is plotted
String suffix=""
IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
	suffix="_Fac"+num2Str(FactorOrder[0])
ENDIF

String graphname=MPplot_MakeGraphName("factorBubble_",folderStr1,suffix)

// set plot width
Variable plotWidth=1000
IF (noc==1)
	plotWidth=500
ENDIF	

// get other waves
Wave OCfactor
Wave OScfactor
Wave/T Compfactor

Wave ElementNum			// getfactors() should have created these Waves (issue if length changes)
Wave/D OSc_ions

IF (!Waveexists(ElementNum))	// check tha these waves exist
	abortStr="MPplot_plotPMFmsBubble():\r\rWave 'ElementNum' not found in PMF results folder: \r"+folderPath
	MPaux_abort(AbortStr)
ENDIF

IF (!Waveexists(OSc_ions))	// calculate OSc_ions if element numbers are there
	
	Make/D/O/N=(dimsize(ElementNum,0)) OSc_ions
	Wave/D OSc_ions=OSc_ions
	
	OSc_ions= 2*ElementNum[p][2]/ElementNum[p][0] - ElementNum[p][1]/ElementNum[p][0]
	
ENDIF

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.03				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(numpnts(factorOrder))+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// prepare window
Killwindow/Z $graphName	// Igor 7 introduced Z flag
Display/W=(50,50,plotWidth,600) as graphName
Dowindow/C $graphName

Variable ff=0,IDidx
String currentZstr, traceList,currentTrace,CurrentAxis
String textStr="\\Z14"

FOR (ff=0;ff<numpnts(FactorOrder);ff+=1)
	
	IDidx=FactorOrder[ff]	// number of current factor 
			
	currentZstr="factor_MS"+num2str(IDidx)
	Wave zwave=$currentZStr
	Wave ywave=OSC_ions
	Wave xwave=ElementNum
	
		//---------------------------------
	// define draw values
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// panels in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// panels in each coloumn
	
	//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF

	Variable DrawBottomStart= CurrentCol*Drawinterval
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF
	DrawBottomEnd-=space/2
	
	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+1
	Variable LegYPos=100-100*DrawEnd

	//---------------------------------

	//do plot
	CurrentAxis="L"+num2Str(ff)
	
	appendtograph/L=$(CurrentAxis)/B=$(XaxisName) ywave vs xwave[][0]
	
	traceList=Tracenamelist("",";",1)
	currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
	
	// 	make bubbles
	ModifyGraph zmrkSize($CurrentTrace)={zWave,*,*,1,10}
	
	// colour and legendstring

	textStr+="Factor " +num2str(IDidx) +" "
	IF (waveexists(CompFactor))
		textStr+=CompFactor[IDidx-1]+"\r"
		textStr+="\tOC: "+num2str(round(OCfactor[IDidx-1]*100)/100) +" OSc: "+num2str(round(OScfactor[IDidx-1]*100)/100) 
	ENDIF
	
	TextBox/C/B=1/N=$("Leg"+num2str(IDidx))/A=RT/Y=(LegYPos)/X=(LegXpos) textStr
	
	Variable ColourIdx=ff
	// catch if single factor is plotted
	IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
		ColourIdx=FactorOrder[0]-1
	ENDIF

	colourIDX-=floor(ff/22)*dimsize(colourwave,0)
	
	ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
	// make everything <threshold transparent
	ModifyGraph zcolor($CUrrentTrace)={zWave,threshold,threshold*1.0001,rainbow,0},zcolorMax($CUrrentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2]),zcolorMin($CUrrentTrace)=NaN
	
	// set axis properties
	ModifyGraph axisEnab($YAxisName)={DrawStart,DrawEnd}, tick($YAxisName)=2,nticks($YAxisName)=2
	SetAxis $YAxisName -1.9,2.9
	
	ModifyGraph mirrorPos($YAxisName)=DrawMirror
	
	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd},gridEnab($YAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)
	
	//reset legendStr
	textStr="\\Z14"
ENDFOR

// axis
ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,lblPos=70,lblLatPos=0,notation=1
ModifyGraph grid=2,gridHair=1,gridRGB=(0,0,0)

Label L0 "OSc"

// handle multiple x axis
String bottomName=""
Variable ii

FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname "number of C"

	SetAxis $Bottomname 0,*
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction},mirror($Bottomname)=2
	
	ModifyGraph minor($Bottomname)=1,sep($Bottomname)=20

ENDFOR

//grid lines for last column
Modifygraph gridEnab($BottomName)={0,lastgrid},mirrorPos($BottomName)=lastGrid

// traces
ModifyGraph mode=3,marker=19,useMrkStrokeRGB=1

// clean up
SetDrawLayer UserFront

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot factor spectra as mass defect plot

FUNCTION MPplot_plotPMFmassdefect(folderStr,nSol,Wavenames[,panelNumber,order,threshold])

String FolderStr			// solution folder
Variable nSol			// number of factors
Wave/T Wavenames			// names of data waves
Variable panelnumber	// columns per panel
Variable threshold		// minimum threshold
Wave order				// order of factors
	
setdatafolder root:

// check optional parameters
IF (paramIsDefault(threshold))
	threshold=0.0001
ENDIF
IF (threshold==0)	// catch 0
	threshold=1e-6
ENDIF

IF (paramisdefault(order))
	Make/O/D/N=(nsol) defaultOrder=p+1
	Wave/D defaultOrder
	Wave FactorOrder=defaultOrder
ELSE
	Wave FactorOrder=order
	
ENDIF

Variable nof=numpnts(FactorOrder)	// number of panels in plot

IF(Paramisdefault(panelNumber))
	panelNumber=nof
ENDIF

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFmassdefect():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check if factor MS and time series waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderPath)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPplot_plotPMFmassdefect():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	abortSTr="MPplot_plotPMFmassdefect():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderPath
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
	// print more details into History window
	print "------------------"
	print "Check Wavenames in folder: "+folderPath
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	 
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

// get stuff set for plotting
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

// catch if single factor is plotted
String suffix=""
IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
	suffix="_Fac"+num2Str(FactorOrder[0])
ENDIF

String graphname=MPplot_MakeGraphName("factorMassDef_",folderStr1,suffix)

// make axis draw range
Variable plotWidth=1000
IF (noc==1)
	plotWidth=500
ENDIF

// get basic waves (these were created by getfacotr())
Wave OCfactor
Wave OScfactor
Wave/T Compfactor

Wave ElementNum			
Wave exactMZ=$(Wavenames[%MZname])

IF (!Waveexists(ElementNum))	// check that these waves exist
	abortStr="MPplot_plotPMFmsMassdefect():\r\rWave 'ElementNum' not found in PMF results folder: \r"+folderPath
	MPaux_abort(AbortStr)
ENDIF

IF (Waveexists(exactMZ))	// calculate OSc_ions if element numbers are there
	
	Make/D/O/N=(dimsize(ElementNum,0)) MassDefect_ions
	Wave/D MassDefect_ions=MassDefect_ions
	
	MassDefect_ions=exactMZ[p]-round(exactMZ[p])
ELSE
	abortStr="MPplot_plotPMFmsMassdefect():\r\rWave"+Wavenames[%MZname]+" not found in PMF results folder: \r"+folderPath
	MPaux_abort(AbortStr)
ENDIF

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.04				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(numpnts(factorOrder))+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF


// prepare window
Killwindow/Z $graphname	// Igor 7 introduced Z flag
Display/W=(50,50,plotWidth,600) as graphname
Dowindow/C $graphname

Variable ff=0,IDidx
String currentZstr, traceList,currentTrace
String textStr="\\Z14"

FOR (ff=0;ff<numpnts(FactorOrder);ff+=1)
	
	IDidx=FactorOrder[ff]	// number of current factor 
			
	currentZstr="factor_MS"+num2str(IDidx)
	Wave zwave=$currentZStr
	Wave ywave=MassDefect_ions
	Wave xwave=exactMZ
	
	//---------------------------------
	// define draw values
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// panels in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// panels in each coloumn
	Variable LastGrid=1
	
	//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF

	Variable DrawBottomStart= CurrentCol*Drawinterval
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF
	DrawBottomEnd-=space/2

	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+1
	Variable LegYPos=100-100*DrawEnd

	//---------------------------------
	
	// do plot
	appendtograph/L=$(YAxisName)/B=$(XaxisName) ywave vs xwave[][0]
	
	traceList=Tracenamelist("",";",1)
	currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
	
	// 	make bubbles
	ModifyGraph zmrkSize($CurrentTrace)={zWave,*,*,1,10}
	
	// colour and legendstring

	textStr+="Factor " +num2str(IDidx) +" "
	IF (waveexists(CompFactor))
		textStr+=CompFactor[IDidx-1]+"\r"
		textStr+="\tOC: "+num2str(round(OCfactor[IDidx-1]*100)/100) +" OSc: "+num2str(round(OScfactor[IDidx-1]*100)/100) 
	ENDIF
	
	TextBox/C/B=1/N=$("Leg"+num2str(IDidx))/A=RT/Y=(LegYpos)/X=(LegXpos) textStr

	Variable ColourIdx=ff
	// catch if single factor is plotted
	IF (!paramisdefault(order) && numpnts(FactorOrder)==1)
		ColourIdx=FactorOrder[0]-1
	ENDIF

	colourIDX-=floor(ff/22)*dimsize(colourwave,0)
	
	ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
	// make everything <0.001 transparent
	ModifyGraph zcolor($CUrrentTrace)={zWave,threshold,threshold*1.001,rainbow,0},zcolorMax($CUrrentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2]),zcolorMin($CUrrentTrace)=NaN
	
	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd},gridEnab($YAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)
	
	//reset legendStr
	textStr="\\Z14"
ENDFOR

// axis
ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,lblPos=70,lblLatPos=0,notation=1
ModifyGraph grid=2,gridHair=1,gridRGB=(0,0,0)

Label L0 "mass defect"

// handle multiple x axis
String bottomName=""
Variable ii
FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname "neutral molecule mass"

	SetAxis $Bottomname 0,*
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction},mirror($Bottomname)=2
	Modifygraph manTick($Bottomname)={0,100,0,0},manMinor($Bottomname)={0,0}
ENDFOR

//grid lines for last column
Modifygraph mirrorPos($BottomName)=lastGrid,gridenab($BottomName)={0,lastgrid}

SetDrawLayer UserFront

// traces
ModifyGraph mode=3,marker=19,useMrkStrokeRGB=1,Tick=2

// clean up
Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot VBS distributions

FUNCTION MPplot_plotPMFVBS(FolderStr,ExpListName,FactorVBS,FactorList,TmaxInv,TmaxErr,[panelNumber])

String FolderStr, ExpListName
Wave FactorVBS // 2D wave: row: Factor column: Experiment
Wave FactorList // list with factor numbers to be plotted	=> This is the same as Factor Order in other plotting functions!
Wave TmaxInv, TmaxErr	// 2D wave: TMax^-1 and errors 
Variable panelNumber	// number of panel per column

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFVBS():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

Wave logCstar_split=logCstar_split

String xlabel
IF (Waveexists(logCstar_split))
	Wave xWave=logCstar_split
	Wave errWave=logCstarErr_split
	xlabel="log10(C*)"
ELSE
	Wave xwave= FactorTmaxI
	Wave errWave= FactorTmaxIErr
	xlabel="1/Tmax / K\S-1"
ENDIF

Variable nof=dimsize(FactorVBS,1)	// number of factors  (can be with split ones)

Wave/T ExpList=$(ExpListName)
Variable nop=numpnts(Explist)	// number of panels

// warning for high number of samples
String alertStr=""
IF (nop>22)
	alertStr="WARNING: There are "+num2str(nop)+" samples in your data set. \rContinue plotting?"
	DoALert 1, alertStr
	IF (V_flag==2)
		abort
	ENDIF
ENDIF

// prepare VBS plot
String folderstr1=folderstr

IF (itemsinlist(folderstr,":")>1)	// check for subfolders -> use last entry
	folderStr1=stringfromlist(itemsinlist(folderstr,":")-1,folderStr,":")
ENDIF

String graphname=MPplot_MakeGraphName("VBS_",folderStr1,"")

// set up values for multi column drawing
IF(Paramisdefault(panelNumber))
	panelNumber=numpnts(expList)
ENDIF

IF (panelNumber>numpnts(expList))	// catch if less factors/samples than maximum
	panelnumber=numpnts(expList)
ENDIF

Variable noc=ceil(numpnts(expList)/panelNumber)	//number of columns

// set plot width
Variable plotWidth=1000
IF (noc==1)
	plotWidth=500
ENDIF	

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.04			// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(nop)+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// prepare Graph window
Killwindow/Z $graphName
Display/W=(50,20,plotWidth,600) as graphName
DoWIndow/C $graphName

// loop through experiments
Variable ee,ct=1
String YaxisName=""
String TraceName=""
String LegStr=""

FOR (ee=0;ee<nop;ee+=1)
	
	// define drawing parameters
	Variable CurrentCol=floor(ee/panelNumber)	// current column
	
	String XAxisName="B"+num2Str(CurrentCol)
	
	Variable DrawStart=1-(ee+1)*1/panelNumber	+ CurrentCol		// Start Panel in each coloumn
	Variable DrawEnd=1-(ee)*1/panelNumber + CurrentCol	// End panel in each coloumn
	Variable lastgrid=1
	
		//handle last column
	IF(MOD(numpnts(expList),panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(numpnts(expList),panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ee+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ee+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(numpnts(expList),panelNumber))*1/panelNumber
	ENDIF
	
	Variable DrawBottomStart= CurrentCol*Drawinterval	// bottom axis start
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval	//bottom axis end

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF	
	DrawBottomEnd-=space/2
	
	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	Variable LegXpos=100-DrawbottomEnd*100+2
	Variable LegYPos=100-100*DrawEnd+2

	YaxisName="L"+num2str(ee)
	
	appendtograph /L=$YaxisName/B=$XAxisname FactorVBS[ee][] vs xwave[ee][] 
	
	TraceName=Tracenamelist("",";",1)
	TraceName=Stringfromlist(Itemsinlist(TraceName)-1,TraceName)
	ErrorBars/L=2 $TraceName, X,wave=(errWave[ee][*][0],errWave[ee][*][1])
	
	Variable ColourIdx=ee
	colourIDX-= floor(ee/22)*dimsize(colourwave,0)	// catch more than 22 colours
	
	ModifyGraph rgb($TraceName)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
	ModifyGraph textMarker($TraceName)={FactorList,"default",1,0,1,0.00,0.00}
	
	Modifygraph axisenab($YaxisName)={DrawStart,DrawEnd} 
	Modifygraph nticks($YaxisName)=3
	
	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd},mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)

	// set panel Label
	String TextStr="\\Z16 "+ExpList[ee]
	
	TextBox/C/N=$("text"+num2str(ee+1))/F=0/B=1/A=RT/X=(LegXPos)/Y=(LegYpos) textStr	

	// legendstr entry
	legStr+="\s("+Tracename+") "+expList[ee]+"\r"
	
	SetAxis $YaxisName 0,*

ENDFOR

ModifyGraph mode=8,lsize=10
ModifyGraph tick=2,mirror=1,fStyle=1,fSize=16,axThick=2,lowTrip=0.01,standoff=0,notation=1

Label L0, "normalised signal fraction"
ModifyGraph lblPos(L0)=60

// add title label
String titleStr="\\Z16\\f01"+folderstr1

TextBox/C/N=text1/F=0/A=MT/X=0.00/Y=3 titleStr

// set legend
legStr=removeending(legstr,"\r")
Legend/LT LegStr

// handle multiple x axis
String bottomName=""
Variable ii
Variable Xmin=0
Variable Xmax=210
Variable TickMain=50
Variable TickMinor=4

FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname Xlabel

	//SetAxis $Bottomname Xmin,Xmax
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction}

	//ModifyGraph minor($Bottomname)=0,manTick($Bottomname)={0,TickMain,0,0},manMinor($Bottomname)={Tickminor,0}

ENDFOR

// set mirror axis position for last column
Modifygraph mirrorPos($BottomName)=lastGrid,gridenab($BottomName)={0,lastGrid}

// clean up	
SetDrawLayer UserFront

// clean up
killwaves/Z axisDraw

Setdatafolder $oldFOlder

END

//======================================================================================
//======================================================================================

// plot factor contributions stacked (Bar PLot)
// right folder must be set

FUNCTION MPplot_plotPMFFactorContrib(FolderStr,FactorContrib,FactorList,XwaveStr[,graphName])

String FolderStr
Wave FactorContrib // 2D wave: column: Factor, row: Experiment
Wave FactorList // list with factor numbers to be plotted
String XwaveStr	// wave of x wave !!! can be numberic or text wave
String Graphname

// check xwave type
Variable type=0	// 0: time stamp
String xlabel="time"

IF (WaveType($XwaveStr,1)==1)
	// numeric wave --> time stamps
	Wave xwaveNum=$XwaveStr
ELSE
	// text wave --> labels for category plot
	Wave/T CatLabel=$XWaveStr
	Type=1
	xlabel=""
ENDIF

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFVBSbars():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------
Variable nof=dimsize(FactorContrib,0)	// number of factors  (can be with split ones)

// prepare plot
String PlotName
IF (paramisdefault(Graphname))
	PlotName=MPplot_MakeGraphName("FactorContrib_",StringfromLIst(Itemsinlist(FolderStr,":")-1,FolderStr,":"),"")
ELSE
	PlotName=Graphname	

	// check if graphname is ok
	Variable MaxLength=31
	IF (Igorversion()>=8.00)
		MaxLength=255
	ENDIF
	// set generic name instead	
	IF (strLen(PlotName)>MaxLength)
		plotName=UniqueName("FactorContrib_",6,0)
		Print "Passed Graph name is too long -> using this instead: "+plotName

	ENDIF
ENDIF

Variable plotWidth=500

Killwindow/Z $plotName
Display/W=(50,20,plotWidth,300) as plotName
DoWIndow/C $plotName

// loop through experiments
Variable ee
Variable IDidx

String TraceName=""
String LegStr=""

FOR (ee=0;ee<numpnts(factorList);ee+=1)
	
	IDidx=FactorList[ee]-1
	
	IF (type==0)
		// time stamp
		appendtograph FactorContrib[][IDidx] vs XwaveNum
	ELSE
		// category
		appendtograph FactorContrib[][IDidx] vs CatLabel
	ENDIF
	
	TraceName=Tracenamelist("",";",1)
	TraceName=Stringfromlist(Itemsinlist(TraceName)-1,TraceName)
	
	Variable ColourIdx=ee	//catch more than 22 colours
	colourIDX-=floor(ee/22)*dimsize(colourwave,0)
	
	ModifyGraph rgb($TraceName)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
	
	// legendstr entry
	legStr+="\s("+Tracename+") F"+num2str(ee+1)+"\r"
ENDFOR

SetAxis left 0,*

// make into bar plot	
IF (type==1)
	ModifyGraph mode=5,hbFill=3,toMode=3,catGap(bottom)=0.4
ELSE
	ModifyGraph mode=1,lsize=5,toMode=3
ENDIF

ModifyGraph tick=2,mirror=1,fStyle=1,fSize=16,axThick=2,lowTrip=0.01,standoff=0,notation=1
ModifyGraph tick(bottom)=0,mirror(bottom)=2

// make labels
Label bottom, xlabel
Label Left, "signal contribution"
ModifyGraph lblPos(Left)=60
IF (Type==1)	// category plot
	MOdifyGraph tkLblRot(bottom)=45
ENDIF


// add title label
String titleStr=""
titleStr+=  "\\Z16\\f01"+StringfromLIst(Itemsinlist(FolderStr,":")-1,FolderStr,":")
TextBox/C/N=text1/F=0/A=MT/X=0.00/Y=3 titleStr


// set legend
legStr=removeending(legstr,"\r")
Legend/LT LegStr

// clean up
setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// plot Tmax values for factors
// right folder must be set

FUNCTION MPplot_plotPMFTmax(FolderStr,FactorTmax,FactorTmaxErr,FactorList,XwaveStr[,panelNumber,graphName])

String FolderStr
Wave FactorTmax // 2D wave with factor Tmax values: row: Factor column: Experiment
Wave FactorTmaxErr // 3D wave with factor Tmax error values: row: Factor column: Experiment, layer minus err;plus error
Wave FactorList // list with factor numbers to be plotted
String XwaveStr	// name of x wave !!! can be numberic or text wave
Variable panelNumber
String Graphname

// check xwave type
Variable type=0	// 0: time stamp
String xlabel="time"

IF (WaveType($XwaveStr,1)==1)
	// numeric wave --> time stamps
	Wave xwaveNum=$XwaveStr
ELSE
	// text wave --> labels for category plot
	Wave/T CatLabel=$XWaveStr
	Type=1
	xLabel = ""
ENDIF

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFVBSbars():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

Variable nof=dimsize(FactorTmax,1)	// number of factors  (can be with split ones)

IF(Paramisdefault(panelNumber))
	panelNumber=nof
ENDIF

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns

// prepare Tmax plot
String PlotName
IF (paramisdefault(Graphname))
	PlotName=MPplot_MakeGraphName("FactorTmax_",StringfromLIst(Itemsinlist(FolderStr,":")-1,FolderStr,":"),"")
ELSE
	PlotName=Graphname	

	// check if graphname is ok
	Variable MaxLength=31
	IF (Igorversion()>=8.00)
		MaxLength=255
	ENDIF
	// set generic name instead	
	IF (strLen(PlotName)>MaxLength)
		plotName=UniqueName("FactorTmax_",6,0)
		Print "Passed Graph name is too long -> using this instead: "+plotName
	ENDIF
	
ENDIF

Variable plotWidth=1000
IF (noc==1)
	plotWidth=500
ENDIF	

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.06				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(numpnts(factorList))+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

Killwindow/Z $plotName
Display/W=(50,20,plotWidth,600) as plotName
DoWIndow/C $plotName

// loop through experiments
Variable ff
Variable IDidx

String TraceName=""
String LegStr=""

FOR (ff=0;ff<numpnts(factorList);ff+=1)
	
	IDidx=FactorList[ff]-1
	
	//------------------------
	// get panel position
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff+1)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// panels in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// panels in each coloumn
	Variable LastGrid=1
	
	//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF
	
	Variable DrawBottomStart= CurrentCol*Drawinterval
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF
	DrawBottomEnd-=space/2

	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)

	//------------
	IF (type==0)
		// time stamp
		appendtograph/B=$XaxisName/L=$Yaxisname FactorTmax[][IDidx] vs XwaveNum
	ELSE
		// category
		appendtograph/B=$XaxisName/L=$Yaxisname FactorTmax[][IDidx] vs CatLabel
	ENDIF
	
	TraceName=Tracenamelist("",";",1)
	TraceName=Stringfromlist(Itemsinlist(TraceName)-1,TraceName)
	
	Variable ColourIdx=ff	//catch more than 22 colours
	colourIDX-=floor(ff/22)*dimsize(colourwave,0)

	// error range
	ErrorBars $Tracename SHADE= {0,5,(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2]),(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])},wave=(FactorTmaxErr[*][0][1],FactorTmaxErr[*][0][0])
		
	ModifyGraph rgb($TraceName)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
		
	// legendstr entry
	legStr+="\s("+Tracename+") F"+num2str(ff+1)+"\r"
	
	// factor label	
	Variable LegYPos=100-(100*DrawEnd)+2
	Variable LegXpos=100-100*DrawbottomEnd+2
	String textStr="\Z14F " +num2str(ff+1)

	TextBox/C/B=1/N=$("Leg"+num2str(ff))/A=RT/Y=(LegYPos)/X=(LegXpos) textStr

	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd},gridEnab($YAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd}
	ModifyGraph mirror($XAxisName)=2

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)
	
ENDFOR

ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=2,ZisZ=1,standoff=0,lblPos=70,lblLatPos=0,Tick=2,nticks=3,notation=1

ModifyGraph mode=4,marker=19,lstyle=3

String yLabel="factor Tmax / ºC"
String Name=NameOfWave(FactorTmax)
IF (StringMatch(Name,"*median*"))
	yLabel="factor Tmedian / ºC"
ENDIF
Label L1 ylabel

// add title label
String titleStr=""
titleStr+=  "\\Z16\\f01"+StringfromLIst(Itemsinlist(FolderStr,":")-1,FolderStr,":")
TextBox/C/N=text1/F=0/A=MT/X=0.00/Y=3 titleStr

// set legend
legStr=removeending(legstr,"\r")
Legend/LT LegStr

// handle multiple x axis
String bottomName=""

FOR (ff=0;ff<(noc);ff+=1)
	Bottomname="B"+num2str(ff)

	Label $Bottomname Xlabel

	SetAxis $Bottomname *,*
	
	// label
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction}

	// ticks
	ModifyGraph minor($Bottomname)=0,manTick($Bottomname)={0,5,0,0},manMinor($Bottomname)={5,0},mirror($Bottomname)=2,tick($BottomName)=0
	
	IF (Type==1)	// category plot
		MOdifyGraph tkLblRot($bottomName)=45
	ENDIF
ENDFOR
// set mirror axis position for last column
Modifygraph mirrorPos($BottomName)=lastGrid,gridenab($BottomName)={0,lastGrid}

// clean up
SetDrawLayer UserFront

setdatafolder $oldFolder

END


//===============================================
//===============================================

// Purpose:	create average Thermogram or diurnal factor contribution plots for PMF factors
//				maximum panelNumber plots above each other -> multiple columns
//				
// Input:		folderStr: 	name of data folder to work on (e.g. "root:PMFresults:Combi_F5_0")
//				Type:			0: average thermogram, 1: diurnal factor contributions
//
// Output:	wave are in new subfolder ":avgFactorThermo"
//				average factor thermogram for each factor in given solution
//				plot with averaged factor thermogram values


FUNCTION MPplot_plotAvgDiel(folderStr,panelNumber,type)

String folderStr 
Variable PanelNumber
Variable Type

//-----------------------------------
// basic checks and setup

String oldFolder=getdatafolder(1)

// use abortstr global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

// check for folder
String FolderPath=folderStr	// assume full folder path
IF (!datafolderexists(folderPath))
	
	// add root:
	folderStr=replacestring("root:",folderStr,"")
	folderPath="root:"+folderStr
	folderPath= replaceString("::",folderPath,":")
	
	IF (!datafolderexists(folderPath))
		
		// add root:PMFResults
		folderpath="root:PMFResults:"+folderStr
		folderPath= replaceString("::",folderPath,":")
		
		IF (!datafolderexists(folderPath))
			abortStr="MPplot_plotPMFVBSbars():\r\rfolder not found: "+folderStr
			MPaux_abort(AbortStr)
		ENDIF
	ENDIF
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

setdatafolder $folderPath

//------------------------------

// define names based on Type
String graphBaseName="avgThermo"
String Subname="avgFactorThermo"
String Xname="Tdesorp_avg"
String Yname="AVGthermo"
String Xlabel="Tdesorp / C"


variable Xmin=0
Variable Xmax=210
Variable TickMain=50
Variable TickMinor=4
Variable IdxErrMinus=1
Variable IdxErrPlus=1

IF (Type==1)
	Subname="factorDiel"	
	graphBaseName="FactorDiel"
	Xname="Time_diur"
	YName="FactorDiel"
	xLabel="time of day / h"
	Xmax=24
	Tickmain=6
	Tickminor=2
	IdxErrMinus=3
	IdxErrPlus=4
ENDIF

Setdatafolder $(FOlderPath+":"+SUbname)

// determine number of columns
Wave anote=$(folderStr+":aNote")
Variable nof=aNote[0]

IF (panelNumber>nof)	// catch if les factors/samples than maximum
	panelnumber=nof
ENDIF

Variable noc=ceil(nof/panelNumber)	//number of columns
Variable lastGrid=1

// check draw size
Variable Drawinterval= 1/noc	// width of column -> dynamic sizing
Variable Space=0.06				// extra Space between columns
IF (Drawinterval<space)
	abortStr="MPplot_plotPMFtseriesSplit():\r\rwidth of columns is getting too small. Chosen settings:\r"
	abortStr+=num2Str(panelNumber)+" panels per column for "+num2str(nof)+" samples -> "+num2str(noc)+ " columns"
	MPaux_abort(abortStr)
ENDIF

// set up graph window 
String GraphName= GraphBaseName+"_"+StringFromList(Itemsinlist(folderStr,":")-1,folderStr,":")
KillWindow/Z $Graphname

Display /W=(300,100,1100,600) as graphName
DoWindow/C $graphname

String legendStr=""


// get X wave
Wave xValues=$Xname

// loop through factors and append to plot
Variable ff=0
FOR (ff=0;ff<nof;ff+=1)

	Wave currentFactor=$(Yname+"_F"+num2Str(ff+1))
	String traceName=Yname+"_F"+num2Str(ff+1)
	
	Variable CurrentCol=floor(ff/panelNumber)	// current column
	
	String YAxisName="L"+num2Str(ff+1)
	String XAxisName="B"+num2Str(CurrentCol)
	
	// define drawing parameters
	Variable DrawStart=1-(ff+1)*1/panelNumber	+ CurrentCol		// panels in each coloumn
	Variable DrawEnd=1-(ff)*1/panelNumber + CurrentCol	// panels in each coloumn
	
	//handle last column
	IF(MOD(nof,panelNumber)!=0 && CurrentCol==noc-1)	//check if last column is full
		Variable EmptyPanels=panelNumber-MOD(nof,panelNumber)	// how many panels i nlast co,lumn will be empty
		// adjust the axis draw value
		DrawStart=1-(ff+1+EmptyPanels)*1/panelNumber	+ CurrentCol		// panels in each coloumn
		DrawEnd=1-(ff+EmptyPanels)*1/panelNumber + CurrentCol	// panels in each coloumn
		
		LastGrid=(MOD(nof,panelNumber))*1/panelNumber
	ENDIF

	Variable DrawBottomStart= CurrentCol*Drawinterval
	Variable DrawBottomEnd= (CurrentCol+1)*Drawinterval

	//IF (CurrentCol>0)	// do not add offset for first column
		DrawBottomStart+=space/2
	//ENDIF
	DrawBottomEnd-=space/2

	Variable DrawMirror=(DrawBottomEnd-DrawBottomStart)/(1-DrawBottomStart)
	
	// plot		
	AppendToGraph/L=$YaxisName/B=$Xaxisname currentFactor[*][0] vs Xvalues
	// error shading !! need to check with diel waves!!!!
	ErrorBars $tracename SHADE= {0,3,(0,0,0,0),(0,0,0,0)},wave=(currentFactor[*][IdxErrPlus],currentFactor[*][IdxErrMinus])

	// colour
	ModifyGraph rgb($traceName)=(ColourWave[ff][0],ColourWave[ff][1],ColourWave[ff][2])	
	
	// factor Legend	
	Variable LegYPos=100-100*DrawEnd+2
	Variable LegXpos=100-DrawbottomEnd*100+2
	String textStr="\Z14F " +num2str(ff+1)

	TextBox/C/B=1/N=$("Leg"+num2str(ff))/A=RT/Y=(LegYPos)/X=(LegXpos) textStr
	
	// axis draw
	Modifygraph mirrorPos($YaxisName)=DrawMirror,	freePos($YaxisName)={DrawBottomStart,kwFraction}
	ModifyGraph axisEnab($Yaxisname)={DrawStart,DrawEnd}
	ModifyGraph axisEnab($XAxisName)={DrawBottomStart,DrawBottomEnd}
	
	ModifyGraph gridEnab($Yaxisname)={DrawBottomStart,DrawBottomEnd}
	
	SetAxis $Yaxisname 0,*

	// devision lines for panels
	SetDrawLayer UserBack
	SetDrawEnv xcoord= prel,ycoord= prel,linethick= 2.5
	DrawLine DrawBottomStart,(1-DrawEnd),DrawBottomEnd,(1-DrawEnd)

ENDFOR

ModifyGraph grid=1, tick=2, mirror=1, nticks=2,notation=1, lsize=3, mode=4, Marker=29,msize=5	// markers and lines

ModifyGraph fSize=16,fStyle=1, lowTrip=0.01, standoff=0,notation=1, axThick=2, gridRGB=(26214,26214,26214), gridHair=1
ModifyGraph lblPos(L1)=50, ZisZ=1//, lblLatPos(L1)=-202

Label L1 "scaled factor signal"

SetAxis L1 0,*

// handle multiple x axis
String bottomName=""
Variable ii

FOR (ii=0;ii<(noc);ii+=1)
	Bottomname="B"+num2str(ii)

	Label $Bottomname Xlabel

	SetAxis $Bottomname Xmin,Xmax
	
	ModifyGraph lblPos($Bottomname)=50,lblLatPos($Bottomname)=0
	ModifyGraph freePos($Bottomname)={0,kwFraction}

	ModifyGraph minor($Bottomname)=0,manTick($Bottomname)={0,TickMain,0,0},manMinor($Bottomname)={Tickminor,0}

ENDFOR
// set mirror axis position for last column
Modifygraph mirrorPos($BottomName)=lastGrid,gridenab($BottomName)={0,lastGrid}
	
SetDrawLayer UserFront

SetDataFolder $oldFolder


END

//===============================================
//===============================================

// Purpose:	make colour wave with 22 colours
// Input:
// Output:	Colour Wave with 22 unique colours

FUNCTION MPplot_makeColourWave()

// check for App folder (if standalone call)
Newdatafolder/O root:APP

// make wave
Make/O/D/N=(22,3) root:app:colourwave
Wave ColourWave=root:app:colourwave

colourwave[0][0]= {0,255,0,0,153,153,255,0,0,255,255,0,102,172.191,255,153,191.296,102.767,191.249,255,0.00389105,153}
colourwave[0][1]= {0,0,153,0,0.00389105,153,63.7549,255,255,170,255,170,102,114.755,212.479,50.9767,255,0.00389105,206.829,191.249,135.475,152.992}
colourwave[0][2]= {0,0,0,255,122.401,153,216.922,0,255,0,0,255,102,229.502,127.502,0.00389105,127.502,204,255,242.249,204,0.00389105}		

colourWave*=257
END


//===============================================
//===============================================


// Purpose:	create the name for a graph window
//				check if the length is ok for the Igor version used (31 for 7, 255 for 8)
//				
// Input:		typeStr:			string with the type of name for this graph (e.g. tseries_, factorDiel_)
//				SolutionName: 	name of the solution being plotted (this is the folder name in root:PMFresults 	
//				suffixStr:		suffix for plotting single factor or single sample
//
// Output:	string with name for graph


FUNCTION/S MPplot_MakeGraphName(typeStr,SolutionName,suffixStr)

String TypeStr
String solutionname
String SuffixStr

// name to return: default if something goes wrong is graph_X
String GraphName=UniqueName("Graph_",6,0)

// maximum length of window name
Variable MaxLength=31
IF (Igorversion()>=8.00)
	MaxLength=254
ENDIF

// build name
String Graphname_new=typeStr+solutionName+suffixStr
graphname_New=removeending(graphname_new,"_")	// catch if suffixStr is empty

// if name too long -> use basename with number
IF (strlen(graphname_new)>MaxLength)
	// use typeStr instead
	graphname=UniqueName((typeStr),6,0)
	// check if that is ok
	IF (strlen(graphname)>MaxLength)
		GraphName=UniqueName("Graph_",6,0)
	ENDIF
	
	// tell user of change
	print "'"+graphname_new+"' is too long for an object name -> using this instead: "+graphname
ELSE
	// use created graphname
	graphname=graphname_new	
ENDIF

RETURN GraphName


END

//===============================================
//===============================================


