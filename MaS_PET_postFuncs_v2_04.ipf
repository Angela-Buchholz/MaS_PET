#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//======================================================================================
//	MaS_PET_postFuncs contians the post-PMF-calculation functions for the MaS-PET software. 
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

// this procedure file contains all basic functions needed during Post processing
// Button control and Plot functions are in separate files

//======================================================================================
//======================================================================================

// Purpose:		open PET results panel (step 2)
//					uses saved wave names, skipping popup menu panel

// Input:			
// Output:		PET results panel is opened
//					PET global values are calculated if missing
// called by:	-			


FUNCTION MPpost_openPETresults()

SVAR abortStr=root:APP:abortStr
abortStr=""

// make sure PET globals are right
// PET globals
String PET_names="dataTypeHR;CapVapFlag;"

//MaS-PET globals
String APP_names="dataTypeHR_VAR;CapVapFlag_VAR;"
MPaux_transferPMFparams("APP",APP_names,"pmf_plot_globals",PET_names)

// get globals
svar pmfDFNm = root:pmf_plot_globals:pmfDFNm

// wavenames
svar DataMxNm = root:pmf_plot_globals:DataMxNm
svar StdDevMxNm = root:pmf_Plot_globals:StdDevMxNm
svar ColDescrWvNm = root:pmf_plot_globals:ColDescrWvNm
svar/Z ColDescrTxtWvNm = root:pmf_Plot_globals:ColDescrTxtWvNm
IF (!SVAR_exists(ColDescrTxtWvNm))
	svar/Z ColDescrTxtWvNm = root:pmf_Plot_globals:ColDesTxtWvNm
ENDIF
svar/Z ColDesTxtWvNm = root:pmf_Plot_globals:ColDesTxtWvNm
IF (!SVAR_exists(ColDesTxtWvNm))
	svar/Z ColDesTxtWvNm = root:pmf_Plot_globals:ColDescrTxtWvNm
ENDIF

svar RowDescrWvNm = root:pmf_plot_globals:RowDescrWvNm

Wave/T Waves4PMF=$(pmfDFNm+"Waves4PMF")

// set wavenames from Wave in folder
// !!! this can be different from what is displayed in the APP panel
DataMxNm=Waves4PMF[%MSdataName]
StdDevMxNm=Waves4PMF[%MSerrName]
ColDescrWvNm=Waves4PMF[%MZname]
ColDescrTxtWvNm=Waves4PMF[%LabelName]
ColDesTxtWvNm=Waves4PMF[%LabelName]
RowDescrWvNm=Waves4PMF[%Tname]

//------------------
// check that data waves exist

// added a perhaps unneccessary checks for existence in 1.3C	
NewDataFolder/o $pmfDFNm+"EvaluationPanelGlobals"
	
// make sure that the values from the panel have been transferred
if (exists(pmfDFNm+DataMxNm))			// added a perhaps unneccessary check here
	//string/g $pmfDFNm+"EvaluationPanelGlobals:DataMxNmStr" = DataMxNm
ELSE
	abortStr+="MPpost_openPETresults():\r\rmissing wave: "+pmfDFNm+DataMxNm+"\r"
endif

if (exists(pmfDFNm+StdDevMxNm))			// added a perhaps unneccessary check here
	//string/g $pmfDFNm+"EvaluationPanelGlobals:StdDevMxNmStr" = StdDevMxNm
ELSE
	abortStr+="MPpost_openPETresults():\r\rmissing wave: "+pmfDFNm+StdDevMxNm+"\r"
endif

if (exists(pmfDFNm+ColDescrWvNm))			// added a perhaps unneccessary check here
	//string/g $pmfDFNm+"EvaluationPanelGlobals:ColDescrWvNmStr" = ColDescrWvNm
ELSE
	abortStr+="MPpost_openPETresults():\r\rmissing wave: "+pmfDFNm+ColDescrWvNm+"\r"
endif

if (exists(pmfDFNm+ColDescrTxtWvNm))			// added a perhaps unneccessary check here
	//string/g $pmfDFNm+"EvaluationPanelGlobals:ColDescrTxtWvNmStr" = ColDescrTxtWvNm
ELSE
	abortStr+="MPpost_openPETresults():\r\rmissing wave: "+pmfDFNm+ColDescrTxtWvNm+"\r"
endif

if (exists(pmfDFNm+RowDescrWvNm))			// added a perhaps unneccessary check here
	//string/g $pmfDFNm+"EvaluationPanelGlobals:RowDescrWvNmStr" = RowDescrWvNm
ELSE
	abortStr+="MPpost_openPETresults():\r\rmissing wave: "+pmfDFNm+RowDescrWvNm+"\r"
endif

IF (strlen(abortStr)>0)
	MPaux_abort(abortStr)
ENDIF

// kill the panel
DoWindow/K PMF_Results_Panel

// make global variables
pmf_make_PlotGlobals()

// do extra stuff for AMS data
nvar/z dataTypeHR = root:pmf_plot_globals:dataTypeHR
if (NVar_exists(dataTypeHR) && dataTypeHR>=1)  //3.05E
	
	EALight_globals()
	EALight_CreateDefaultHRfam()
	PK_CreateElementWaves()  //3.08
	pmf_createProfileFamilies()
	EALight_CreateHRFamilyText()
endif

// update all the waves for default panel settings
DoWindow/K  PMF_Plot_Panel		// updates happen faster if we make sure the plot panel is killed

pmf_update_fpeakOrFactorSpace()  //imu2.05  pmf_update_plotWaves()
	
// add elemental ratios
if(dataTypeHR==1)  // we have HROrg
	pmf_butt_ElemRatiosFamCol() 	//3.04B
endif	

// set Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution=?"
Variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

PMF_make_Plot_Panel()

// reset Panel resolution
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

// print names
print "-----------------------"
print date()+" "+time()
print "PET results panel generated with waves in folder: "+pmfDFNm
print Waves4PMF

END


//======================================================================================
//======================================================================================


//======================================================================================
//======================================================================================

// Purpose:		get explained and unexplained variance and Q/Qex for given folder

// Input:			folderStr		folderwith MSdata and PMF output
//					dataName		string name of wave with data matrix
//					type			0: calculate with sumsqr, 1: calulate with sum(abs)
// Output:		wave with un/explained variance
//					plot with variance and Q/Qexp for all solutions and all fpeaks
// called by:	-			

FUNCTION MPpost_calcExpVariance(folderStr,dataName,type)

Variable type
String folderStr
String dataName	// typical MSdata or NoNaNs_MSdata

//set datafolder with PMF raw results
String fullPath="root:"+folderStr
fullpath=replaceString("root:root",fullpath,"root")
setdatafolder $(fullpath)

// get waves
Wave MSdata=$(dataName)

Wave Gmx4D,Fmx4D,fpeakMap,Qmx2D,TotalSignal_as_tSeries,TotalSignal_as_massSpec,fpeak_map,p_map,Var_PMFresultsMx4D

// check that wave dimensions match
IF (numpnts(TotalSignal_as_MassSpec) != dimsize(MSdata,1))
	abort "MPpost_calcExpVariance():\r\rdimensions if MSdata wave and TotalSignal_as_MassSpec wave do not agree.\rcheck MSdata wave name"
ENDIF

// get info on solutions and f peak number
Variable fpeakNum=dimsize(Gmx4D,2)	// number of layers in G
Variable solNum=dimsize(Gmx4D,1)		// number of columns in G
Variable ionNum=dimsize(msdata,1)	// number of ions
Variable timeNum=dimsize(msdata,0)	// number of time stamps

// make Wave for variances
Make/D/O/N=(solNum*fpeakNum) idx4Variance=p+1,VarExp_time=NaN,VarExp_mass=NaN,VarUnexp_time=NaN,VarUnexp_mass=NaN,VarExp_All=NaN,VarUnexp_All=NaN,RecovSignal=NaN
Make/T/O/N=(solNum*fpeakNum) label4Variance
Make/FREE/D/N=(ionNum)	tempAvgMass=NaN	
Make/FREE/D/N=(timeNum) tempAvgTime	=NaN
Make/FREE/D/N=(timeNum,ionNum) tempAvgAll	=NaN
note RecovSignal,"fraction of recovered signal (total sum of measured data-sum of reconstructed signal)"

// calc average from data
Wavestats/Q/PCST msdata
Wave M_Wavestats
tempAvgMass=M_wavestats[3][p]

MatrixTranspose MSdata
Wavestats/Q/PCST msdata
Wave M_Wavestats
tempAvgtime=M_wavestats[3][p]
Matrixtranspose msdata

Wavestats/Q msdata
tempAvgAll=V_avg

// measured - average values
IF (type==1)	// calculate with absolute distance
	MatrixOP/FREE/O VarTot_time=sum(abs(TotalSignal_as_tSeries-tempAvgTime))		// summed over all masses	-> time series
	MatrixOP/FREE/O VarTot_mass=sum(abs(TotalSignal_as_MassSpec-tempAvgMass))	// summed over all times -> mass spec
	MatrixOP/FREE/O VarTot_All=sum(abs(MSdata-tempAvgAll))
ELSE	// calculate with square of distance
	MatrixOP/FREE/O VarTot_time=sumsqr(TotalSignal_as_tSeries-tempAvgTime)		// summed over all masses	-> time series
	MatrixOP/FREE/O VarTot_mass=sumsqr(TotalSignal_as_MassSpec-tempAvgMass)	// summed over all times -> mass spec
	MatrixOP/FREE/O VarTot_All=sumsqr(msdata-tempAvgAll)
ENDIF

// sum up over other domain
Make/D/O/N=(3) VarTot
Note VarTot,"total Variance for measured data\rrow 0: as time series, row 1: as mass spectrum, row3: over everything"
VarTot[0]=VarTot_time[0]
VarTot[1]=VarTot_mass[0]
VarTot[2]=VarTot_all[0]

//--------------------------------------------------
// calculate reconstructed data and residual matrix 
// data = G x F + E
//// Reconstructed data R = G x F	
//Make /D/O/N=(timeNum,ionNum,fpeakNum,SolNum) Rmx4D=NaN //,Emx4D=NaN,Emx4D_2=NaN	// each layer is one solution, each chunk one Fpeak
//
//Note Rmx4D, "reconstructed matrix= GxF\rlayers are 1 solution with multiple fpeaks; chunks are solutions"

Make/D/O/N=(solNum*fpeakNum,2) infoAllSolutions=NaN
Make/D/O/N=(solNum*fpeakNum) QAllSolutions=NaN
Note infoAllSolutions, "column 0: number of factors, column 1: fpeak/seed values"

Make/D/O/N=(solNum*fpeakNum,ionNum) RasMassSpec=NaN
Make/D/O/N=(solNum*fpeakNum,timeNum) RasTseries=NaN
Note RasMassSpec,"integrated mass spectra for each solution\rone row for each solution with one f peak"
Note RasTseries,"TIC for each solution\rone row for each solution with one f peak"

Variable ss=0,ff=0,ct
Make/FREE/D /N=(timeNum,solNum) tempG=NaN	//Time series
Make/FREE/D /N=(solNum,ionNum) tempF=NaN	//MS series	

Make/FREE/D/N=(solNum) tempFracs=NaN	//

// catch if first solution is NOT F=1
Variable minFacNum=p_map[0]
ct+=(minfacNum-1)*fpeakNum	// set to first entry

FOR (ss=0;ss<dimsize(Qmx2D,1);ss+=1)	// one solution catch if not from 1-max number of factors

	FOR (ff=0;ff<fpeakNum;ff+=1)	// each fpeak in one solution

		IF (numtype(Qmx2D[ff][ss])==0)	// check if data converged (=Q/Qexp value exists)
			tempF=Fmx4D[p][q][ff][ss]
			tempG=Gmx4D[p][q][ff][ss]
			
			// change NaN to 0
			tempF = numtype(tempF[p][q])==0 ? tempF[p][q]:0
			tempG = numtype(tempG[p][q])==0 ? tempG[p][q]:0
			
			// calc reconstructed matrix for one solution set and one f peak
			MatrixOp/Free tempR=tempG x tempF 
			//Rmx4D[][][ff][ss]=tempR[p][q]	// reconstructed
					
			// put as tseries and as mass series in each row
			Sumdimension/D=0 /dest=tempMS tempR
			Sumdimension/D=1 /dest=tempTseries tempR
			
			RasMassSpec[ct][]=tempMS[q]
			RasTseries[ct][]=tempTseries[q]
			
			// calculate variances
			IF(type==1)	// abs(sum)
				
				// Unexplained variance time (measured - model)
				MatrixOp/FREE temp_UnExp1=sum(abs(totalSignal_as_tseries-tempTseries)	)// sum{(data-model)^2} -> one value
				// Unexplained variance mass
				MatrixOp/FREE temp_Unexp2=sum(abs(totalSignal_as_massSpec-tempMS))
				// Unexplained variance All
				MatrixOp/FREE temp_Unexp3=sum(abs(msdata-tempR))
				
				
				// explained variance time (model - average(data))
				MatrixOp/FREE temp_Exp1=sum(abs(tempTseries-tempAvgTime)	)// sum{abs(model-average)} -> one value
				// explained variance mass
				MatrixOp/FREE temp_Exp2=sum(abs(tempMs-tempAvgmass))	// sum{abs(model-average)} -> one value
				// explained variance mass
				MatrixOp/FREE temp_Exp3=sum(abs(tempR-tempAvgAll))	// sum{abs(model-average)} -> one value
			
			ELSE	// sumsqr
			
				// Unexplained variance time (measured - model)
				MatrixOp/FREE temp_UnExp1=sumsqr(totalSignal_as_tseries-tempTseries)	// sum{(data-model)^2} -> one value
				// Unexplained variance mass
				MatrixOp/FREE temp_Unexp2=sumsqr(totalSignal_as_massSpec-tempMS)
				// Unexplained variance All
				MatrixOp/FREE temp_Unexp3=sumsqr(MSdata-tempR)
				
				// explained variance time (model - average(data))
				MatrixOp/FREE temp_Exp1=sumsqr(tempTseries-tempAvgTime)	// sum{(model-average)^2} -> one value
				// explained variance mass
				MatrixOp/FREE temp_Exp2=sumsqr(tempMs-tempAvgmass)	// sum{(model-average)^2} -> one value
				// explained variance mass
				MatrixOp/FREE temp_Exp3=sumsqr(tempR-tempAvgAll)	// sum{(model-average)} -> one value

			ENDIF

			VarUnexp_time[ct]=temp_UnExp1[0]
			VarUnexp_mass[ct]=temp_UnExp2[0]
			VarUnexp_all[ct]=temp_UnExp3[0]

			VarExp_time[ct]=temp_Exp1[0]
			VarExp_mass[ct]=temp_Exp2[0]
			VarExp_all[ct]=temp_Exp3[0]

			// fraction of reconstructed mass
			tempFracs=var_pmfresultsMX4D[3][p][ff][ss]	//row 3 contains mass fraction for each factor
			tempFracs = numtype(tempFracs[p])==0? tempFracs[p] : 0	// replace Nans
			RecovSignal[ct]=sum(tempFracs)
		ENDIF
		
		idx4Variance[ct]=ct+1
		label4Variance[ct]="F"+num2Str(p_map[ss]+1)+"_"+num2str(fpeak_map[ff])
		infoAllSolutions[ct][0]=p_map[ss]
		infoAllSolutions[ct][1]=fpeak_map[ff]
		
		QallSolutions[ct]=Qmx2D[ff][ss]
		
		ct+=1	// increase counter
	ENDFOR
	
ENDFOR
Killwaves/Z tempTseries,tempMS

// get exp/total
Make/O/D/N=(solNum*fpeakNum,3) VarRatio_exp_tot=NaN,VarRatio_unexp_tot=NaN
Note VarRatio_exp_tot, "ratio of explained/total variance\rone row for each solution with one f peak\rcolumn0: as time series, column 1: as mass spectrum"

VarRatio_exp_tot[][0]=VarExp_time[p]/VarTot[0]
VarRatio_unexp_tot[][0]=VarUNExp_time[p]/VarTot[0]

VarRatio_exp_tot[][1]=VarExp_mass[p]/VarTot[1]
VarRatio_unexp_tot[][1]=VarUNExp_mass[p]/VarTot[1]

VarRatio_exp_tot[][2]=VarExp_all[p]/VarTot[2]
VarRatio_unexp_tot[][2]=VarUNExp_all[p]/VarTot[2]

//--------------------------------------------
// quick plot with explained variances and Q

String foldername=Stringfromlist((Itemsinlist(folderStr,":"))-1,folderStr,":")
String graphName=MPplot_MakeGraphName("Variance_",FolderName,"")

Killwindow/Z $graphName

display /W=(50,50,500,350) as graphname
Dowindow/C $graphname
appendtograph varRatio_unexp_tot[][0] vs idx4Variance
appendtograph varRatio_exp_tot[][0] vs idx4Variance
appendtograph/R QAllSolutions vs idx4Variance

ShowInfo

// make it pretty
ModifyGraph mode=1,lsize=10
ModifyGraph rgb(varRatio_exp_tot)=(3,52428,1),rgb(VarRatio_unexp_tot)=(43690,43690,43690)
ModifyGraph toMode(VarRatio_unexp_tot)=3
ModifyGraph mirror(bottom)=2,fStyle=1,fSize=16,axThick=2,standoff=0,notation=1

ModifyGraph mode(QAllSolutions)=3,marker(QAllSolutions)=19,rgb(QAllSolutions)=(0,0,0)

ModifyGraph manTick(bottom)={0,fpeakNum,0,0},manMinor(bottom)={0,0}
ModifyGraph grid(bottom)=2,gridRGB(bottom)=(0,0,0)

// axis
Setaxis bottom, 0,Wavemax(idx4Variance)+0.5
Setaxis left, 0,*
Setaxis right, 0,*

// legend
String LegendStr="\f01\Z16\s(QallSOlutions) Q/Q\Bexp\M\f01\Z16\rVariance\r\s(Varratio_unexp_tot) unexplained\r\s(Varratio_exp_tot) explained"
Legend LegendStr
Label left, "un/explained / total Variation"
Label right,"Q/Qexp"
Label bottom,"ID"

// 1 line
Setdrawlayer Userback
SetDrawEnv ycoord= left,dash= 3,linethick= 2.50
DrawLine 0,1,1,1

END

//======================================================================================
//======================================================================================

// Purpose:		extract Factor time series and spectra from 4D results wave. 
//					
// Input:			PMF data must exist
//					ExpListStr:	name of explist wave
//					folderStr:	name of Folder with PMF results
//					nSol:			number of factors (solution)
//					fpeak:			fpeak value to use
//					wavenames:	text wave with names of data waves order: MSdata,MSerror,exactMZ,ionLabel,Tdesorp
//					noplot:		1: do not create plots at the end
//					MStype:		which type of data -> do some things only for FIGAERO TD
// Output:		new folder with solution data: root:PMFresults:FolderStr_Fx
//					factorX_rel	mass spec of factor, relative contributions
//					factorX_abs	mass spec of factor absolute signal
//					ThermoX		time series of factor
//					MSx		mass spectrum for each factor
// called by:	MPbut_step3_button_control() -> but_getSolution or stand-alone			

FUNCTION MPpost_getSolution(ExpListStr,folderStr,nSol,fpeak,wavenames,noplot,MStype)

String expListStr
String FolderStr
Variable nSol
Variable fpeak
Wave/T Wavenames
Variable noplot
Variable MStype

// basic checks
//---------------------------------
// check if abort string ewxist as global
SVAR/Z abortStr=root:APP:abortStr
IF (!SVAR_Exists(abortStr))
	String/G abortStr=""
ENDIF

folderStr=replaceString("root:",folderStr,"")//	remove root if there
String FolderName="root:"+folderStr	// folder name contains root

Setdatafolder root:

// check if expList wave exists
String expListPath="root:"+expListStr
expListPath=replaceString("root:root:",expListPath,"root:")

Wave/T expList=$(ExpListPath)

IF (!Waveexists(ExpList))
	abort "MPpost_getSolution():\r\rexplist wave not found: "+expListStr
ENDIF

// check folder
IF (!datafolderexists(FolderNAme))
	abort "MPpost_getSolution():\r\rno datafolder found with name:\r\r"+folderName
ENDIF

setdatafolder $folderName

// check if data exists
String AllWaves="Gmx4D;Fmx4D;Resid_as_tseries_mx4D;"+wavenames[%MSdataname]+";"+wavenames[%MSerrName]+";"+wavenames[%MZname]+";"
AllWaves+=wavenames[%LabelName]+";"+wavenames[%Tname]+";fpeak_map;"

IF (MStype==2 && !Stringmatch(wavenames[%FigTimeName],""))	// for FIGAERO TD and only if valid entry
	AllWaves+=wavenames[%FigTimeName]+";"
ENDIF

IF (MPaux_CheckWavesFromList(AllWaves)!=1)	// check if all waves exist
	Wave NonExistIdx
	
	abortstr="MPpost_getSolution:\r\r"
	// Print those that don't
	Variable ww
	FOR (ww=0;WW<numpnts(NonExistIdx);ww+=1)
		abortStr+="\rWave "+Stringfromlist(nonexistIDX[ww],allWaves)+" not found in folder "+folderName
	ENDFOR
	MPaux_abort(abortStr)
ENDIF

// get waves
Wave Gmx4D,Fmx4D					// PMF results
Wave Resid_as_tseries_mx4D	// residuals as time series, columns are type (2 is relative)
Wave Resid_as_massSpec_mx4d	// residuals as mass specs, columns are type (2 is relative)
Wave fpeak_map
Wave p_map

Wave temp1=$Wavenames[%TName]
Wave MZ=$Wavenames[%MZname]
Wave/T labels=$Wavenames[%LabelName]
Wave MSdata=$Wavenames[%MSdataName]
Wave Eij=$Wavenames[%MSerrName]	// set this to error that was used

Wave/Z FigTime_ORG=$Wavenames[%FIGTimeName]	// will be null reference if otehr than FIG TD data

// get info about type fpeak/seed
NVAR type=calcedSeedOrFpeak	// 1:seed, 0:fpeak

// check dimension of waves
IF (dimsize(MSdata,1)!=dimsize(Fmx4D,1))
	abortStr="MPpost_getSolution():\r\rnumber of columns does not agree between Fmx4D and MSdata: "+folderName+":"+Wavenames[0]
	abortStr+="\r\rcheck names in panel and Waves4PMF wave in folder"
	MPaux_abort(abortStr)
ENDIF

// check number of factors
Variable posSol
FindValue /V=(nsol) p_map

IF (V_value<0)
	abortstr = "MPpost_getSolution():\r\rnumber of factor value = "+num2str(nsol)+" not found in p_map wave"
	abortStr+="\rin folder: "+folderName
	abortStr+= "\rnumber of factors must be: "+num2str(p_map[0])+" - "+num2Str(p_map[numpnts(p_map)-1]) 
	
	MPaux_abort(abortStr)
ELSE
	posSol=V_value	
ENDIF

// check for fpeak position in data (normaly using fpeak=0)
FindValue /V=(fpeak) fpeak_Map
Variable IDXfpeak=V_value

IF (IDXfpeak<0)
	abortStr= "MPpost_getSolution():\r\rfpeak/seed value = "+num2str(fpeak)+" not found in fpeak_map wave."
	abortStr+="\rin folder: "+folderName+"\rAvailable entries:"
	Variable jj=0
	FOR (jj=0;jj<numpnts(fpeak_Map);jj+=1)
		abortStr+="\r"+num2str(fpeak_Map[jj])+";"
	ENDFOR
	MPaux_abort(abortStr)	
ENDIF

// prepare results containers and get common waves
//---------------------------------

// prepare results folder
newdatafolder/O/S root:PMFresults

// create solution results folder and basic info
String typeStr_short="f"+num2Str(fpeak)	// fpeak
String typeStr_long="fpeak"

IF(type==1)	//seed
	typeStr_short="s"+num2Str(fpeak)
	typeStr_long="seed"
ENDIF

typeStr_short=replaceString("-",typeStr_short,"n")	// change "-" to "n"
typeStr_short=replaceString(".",typeStr_short,"d")	// change "." to "d"

String subfolder=folderStr+"_F"+num2str(nSol)+"_"+typeStr_short

// check length of folder name
subfolder=MPaux_folderName("root:PMFresults:",subfolder,"combi_F"+num2str(nSol)+"_"+typeStr_short+"_")

String newFolder="root:PMFresults:"+subfolder

newdatafolder/S/O $newfolder

// store info about soltion (factor number, rotation value, seed/fpeak
Make/D/O/N=(3) aNote={nsol,fpeak,type}
Note aNote,"solution Number\rfpeak or seed value\r0:fpeak;1:seed"

String Labeldummy="factorNumber"
Setdimlabel 0,0,$labeldummy,aNote
Labeldummy="rotValue"
Setdimlabel 0,1,$labeldummy,aNote
Labeldummy="rotType"
Setdimlabel 0,2,$labeldummy,aNote

// print info
print "------------------"
print date() +" "+time()+" extracting solution with "+num2str(nsol)+ " factors and "+typeStr_long+"="+num2Str(fpeak)+" to:"
print " + " +newFolder

// make ElementNumber wave in PMF results folder
MPaux_calcElementFromLabel(labels)	
Wave ElementNum

// if AMS selected -> check if elemental ratio stuff is there
Variable useAMS=0
IF (MStype==4 || MStype==5)
	IF (Waveexists($(folderName+":ElemRatios_HC_3d")))
		Wave ElemRatios_HC_3d=$(folderName+":ElemRatios_HC_3d")
		Wave ElemRatios_OC_3d=$(folderName+":ElemRatios_OC_3d")
		Wave ElemRatios_NC_3d=$(folderName+":ElemRatios_NC_3d")
		useAMS=1
	ENDIF

ENDIF

// get info for OC etc.
Make/O/D/FREE/N=(dimsize(elementNum,0),9) tempW4Sum	// container for averaging
Make/O/D/N=(nsol) OCfactor,OScfactor,HCfactor,NCfactor,avgMwFactor
Make/O/T/N=(nsol) CompFactor=""

// get waves common for all factors
Make/O/D/N=(numpnts(temp1)) $Wavenames[%Tname]=temp1[p]
Wave temp_series=$Wavenames[%Tname]

Make/O/D/N=(numpnts(MZ)) $Wavenames[%MZname]
Wave exactMZ=$(Wavenames[%MZname])
exactMZ=MZ[p]

Make/O/T/N=(numpnts(labels)) $Wavenames[%Labelname]
Wave/T ionLabel=$Wavenames[%Labelname]
ionLabel=labels[p]
Make/O/D/N=(dimsize(GMx4d,0),dimsize(FMx4d,1)) MS_reconst=0

IF(Waveexists(FigTime_ORG))	// FIG time only if it exists
	Make/O/D/N=(numpnts(temp1)) $Wavenames[%FigTimeName]
	Wave FigTime=$Wavenames[%FigTimeName]
	FigTime=FigTime_ORG
ENDIF

// separate Experiments
//---------------------------------
// if makeCombi was used, Wave idxSample exists -> use that
// get info on sample idx
String IdxSampleName="idxSample"
IF (stringmatch(Wavenames[0],"noNans_*"))	// check if noNans is used
	IdxSampleName="nonans_idxSample"
ENDIF

MPaux_check4IDXSample(IdxSampleName,FolderName,temp_series,ExpList)

Wave idxSample_org=$(folderName+":"+IdxSampleName)

// compare ExpList and idxsample length (only triggers issue if idxSample was created previously)
IF (numpnts(ExpList) != dimsize(idxSample_org,0))
	edit explist,idxSample_org	// show the waves to user
	abortStr="MPpost_getSolution():\r\rdimension of idxSample wave and selected EpxlistWave do not agree. Check input:\r"
	abortSTr+=GetwavesDataFolder(idxSample_org,2)
	abortSTr+=GetwavesDataFolder(explist,2)
	MPaux_abort(abortStr)
ENDIF

// loop through factors to get waves
//---------------------------------

Variable ff,ee
String f_rel="",f_abs="",Factor_TS="",ms=""

FOR (ff=0;ff<nsol;ff+=1)
	// wave names
	f_rel="Factor_MS"+num2str(ff+1)
	Factor_TS="Factor_TS"+num2str(ff+1)
	ms="MS"+num2str(ff+1)
	
	// make waves for data
	Make/O/D/N=(dimsize(FMx4d,1))	$(f_rel)		// factor
	Make/O/D/N=(dimsize(GMx4d,0))	$(Factor_TS)	// tseries
	Make/O/D/N=(dimsize(GMx4d,0),dimsize(FMx4d,1)) $(MS)	 // MS each factor
	
	Wave currentFrel=$(f_rel)
	Wave currentThermo=$(Factor_TS)
	Wave currentMS=$(MS)
	
	// put data into new waves
	// layer is fpeaks
	currentFrel=Fmx4D[ff][p][IDXfpeak][posSol]	// Factor number 1-nsol, chunks 0-(nsol-1)
	currentThermo=Gmx4D[p][ff][IDXfpeak][posSol]
	
	currentMS=currentThermo[p]*currentFrel[q]	// mass spectra for one factor MS&thermogram combination
	MS_reconst+=currentMS	// add data to recombined MS
	
	//calc OC, OSc and average composition
	tempW4Sum[][0]=currentFrel[p]*elementNum[p][2]/elementNum[p][0]	// O:C	
	tempW4Sum[][1]=currentFrel[p]*elementNum[p][1]/elementNum[p][0]	// H:C
	tempW4Sum[][2]=currentFrel[p]*elementNum[p][5]/elementNum[p][0]	// N:C
	tempW4Sum[][3]=currentFrel[p]*elementNum[p][0]
	tempW4Sum[][4]=currentFrel[p]*elementNum[p][1]
	tempW4Sum[][5]=currentFrel[p]*elementNum[p][2]
	tempW4Sum[][6]=currentFrel[p]*elementNum[p][3]
	tempW4Sum[][7]=currentFrel[p]*elementNum[p][4]
	tempW4Sum[][8]=currentFrel[p]*exactMZ[p]
	
	Wavestats/Q/PCST tempW4Sum
	Wave M_Wavestats
	
	IF (useAMS==0)
		// use averages from signal weighted ion values
		OCfactor[ff]=(M_WaveStats[23][0])
		HCfactor[ff]=(M_WaveStats[23][1])
		NCfactor[ff]=(M_WaveStats[23][2])
	ELSE
		// use AMS calculated values
		HCfactor[ff]= ElemRatios_HC_3d[ff][IDXfpeak][posSol]
		OCfactor[ff]= ElemRatios_OC_3d[ff][IDXfpeak][posSol]
		NCfactor[ff]= ElemRatios_NC_3d[ff][IDXfpeak][posSol]
	ENDIF
	
	// composition assuming deprotonation
	CompFactor[ff]+="C"+num2str(round(M_WaveStats[23][3]*10)/10)
	CompFactor[ff]+=" H"+num2str(round(M_WaveStats[23][4]*10)/10)
	CompFactor[ff]+=" O"+num2str(round(M_WaveStats[23][5]*10)/10)
	// add N and S only if they are in ion list
	IF (M_WaveStats[23][5]>0)
		CompFactor[ff]+=" N"+num2str(round(M_WaveStats[23][6]*10)/10)
	ENDIF
	IF (M_WaveStats[23][6]>0)
		CompFactor[ff]+=" S"+num2str(round(M_WaveStats[23][7]*10)/10)
	ENDIF
	
	// average Mw
	avgMwFactor[ff]=(M_WaveStats[23][8])
	
	// remove MSi
	Killwaves/Z CurrentMS
	
ENDFOR // loop through factors

// calculate OSc for each factor
OScfactor=2*OCfactor-HCfactor
IF (M_WaveStats[23][6]>0 ||  M_WaveStats[23][7]>0)
	print "WARNING: sum formulas with N or S detected. Be careful when interpreting OSc values"
	Note OSCfactor,"sum formulas with N or S detected. Be careful when interpreting OSc values"
ENDIF

//get residuals and "Q" 
//----------------------

Make/O/D/N=(numpnts(temp1)) ResidualAbs_tseries,ResidualRel_tseries,Q_Qexp_tseries,TIC_reconst	, TIC_measured// same length as temperature series
Make/O/D/N=(numpnts(MZ)) ResidualAbs_MS,ResidualRel_MS,Q_Qexp_MS

// test for negative values
MatrixOp/FREE test=minVal(msdata)
IF (test[0]<0)
	print "WARNING: at least 1 value in the mass spectra matrix is negative. Be careful when inspecting the relative residual values."
ENDIF

// calculate TIC -> use simple addition
SumDImension /D=1 /dest=TIC_measured MSdata
SumDImension /D=1 /dest=TIC_reconst MS_reconst

// calculate residuals with negative values set to 0
Make/D/O/N=(dimsize(MS_reconst,0),dimsize(MS_reconst,1)) ResAll,Q_all//,ResScaledAll

// for negative values: set msdata entry to 0 before calcualting the residual
resAll= msdata-ms_reconst

//ResScaledAll=resAll/Eij	// scaled residal
Q_all=resAll^2/Eij^2	// Q=(residual scaled by measurement error)^2
	
ResidualAbs_tseries=Resid_as_tseries_mx4D[p][1][IDXfpeak][posSol]	// residual (timeseries, res type, fpeak, solution number)
ResidualRel_tseries=Resid_as_tseries_mx4D[p][3][IDXfpeak][posSol]	// residual / signal

Q_Qexp_tseries=Resid_as_tseries_mx4D[p][5][IDXfpeak][posSol] // Q=(residual/err)^2/Qexp Qexp= (number of ions)-number of factors

ResidualAbs_MS=Resid_as_massSpec_mx4D[p][1][IDXfpeak][posSol]	// residual (mass spec, res type, fpeak, solution number)
ResidualRel_MS=Resid_as_massSpec_mx4D[p][3][IDXfpeak][posSol]	// residual / signal

Q_Qexp_MS=Resid_as_massSpec_mx4D[p][5][IDXfpeak][posSol] // Q=(residual/err)^2/Qexp Qexp= (number of time points)-number of factors

Note Q_All,"Q (=scaled residual) for each ion at each time\rresAll^2/^MSerr2"
//Note ResScaledAll, "scaled residual for all ions"
Note Q_Qexp_tseries, "Q/Qexp for time series (summed over ions) residual^2/err^2\rQexp is (number of ions)-(number of factors)"
Note Q_Qexp_tseries, "Q/Qexp for mass spectra (summed over time points) residual^2/err^2\rQexp is (number of ions)-(number of factors)"


// separate data into 2D waves for experiments
//-----------------------------------------------
Newdatafolder/O :DataSortedBySample	// subfolder for sample by sample waves
// check format of tseries
Variable formatTest=0
IF (temp_series[0]>1e6)
	formatTest=1	// -> time detected
ENDIF

FOR (ee=0;ee<dimsize(IdxSample_org,0);ee+=1)
	String current2D=":DataSortedBySample:"+ExpList[ee]+"_TS"
	String currentArea=":DataSortedBySample:"+ExpList[ee]+"_Farea"
	String currentTmax=":DataSortedBySample:"+ExpList[ee]+"_Tmax"
	
	Make/D/O/N=(IdxSample_org[ee][1]-IdxSample_org[ee][0]+1,nsol+1) $(current2D)	// temp_series, then factors
	Wave temp2D=$(current2D)
	
	Make/D/O/N=(nsol,4) $currentArea	// row: area for each factor, column: integrate, realtive, sum, relative
	Wave tempArea=$(currentArea)
	Note tempArea, "column: integrate, relative, sum, relative"
	temp2D[][0]=temp_series[p+IdxSample_org[ee][0]]
	// reset T offset
	IF (formatTest==0)
		temp2D[][0]-=ee*200	
	ENDIF
	
	Make/D/O/N=(nsol,8) $currentTmax	// Tmax for factors, 4-7 column is invers
	Wave Tmax=$currentTmax
	Tmax=Nan
	Note Tmax, "columns: maximum Factor, TMaxFit, half wight -, half width +\rcolumns 4-7 are corresponding 1/T"
	
	// sort factors into columns
	FOR (ff=0;ff<nsol;ff+=1)	// loop through factors
		// sort data into 2D wave
		Wave ThermoW=$("Factor_TS"+num2str(ff+1))
		temp2D[][ff+1]=ThermoW[p+IdxSample_org[ee][0]]
				
		// calculate factor area
		Make/D/O/N=(dimsize(temp2D,0)) ThermoX,FareaTemp,TseriesTemp	//1D dummy waves
		ThermoX=temp2D[p][ff+1]		//1D wave with factor thermograms
		TseriesTemp=temp2D[p][0]	// 1D temperature series
		
		integrate/METH=1 ThermoX /X=TseriesTemp /D=FareaTemp	// make cumulative distribution
		tempArea[ff][0]=FareaTemp[numpnts(FareaTemp)-1]	// take last point from cummulative
		tempArea[ff][2]=sum(ThermoX)
		
	ENDFOR // loop through factors
	
	// make relative contribution for Factors
	Make/D/O/N=(nsol) tempW=tempArea[p][0]	// dummy wave for sum
	Variable sumInt=sum(tempW)
	tempArea[][1]=tempArea[p][0]/sumInt
	tempW=tempArea[p][2]
	Variable sumSum=sum(TempW)
	tempArea[][3]=tempArea[p][2]/sumSum
	
	// make Tmax first guess
	// this is kinda obsolete because the same things are calculated with MPpost_getFactorContrib()
	// but leave in for now
	IF (MStype==2)
		MPpost_getTmaxFactor(Temp2D,Tmax)
	ENDIF
	
	// clean up
	Killwaves/Z ThermoX,FareaTemp,TseriesTemp,tempW
	
ENDFOR // loop through experiments

// update results folder value
SVAR/Z SolutionFolder=root:APP:SolutionFolder_STR
IF (SVAr_Exists(SolutionFolder))
	solutionFOlder=NewFolder
ENDIF

// set marker for existing folder
NVAR xpos_comp=root:app:xpos_comp
NvAR ypos_box3=root:app:ypos_box3
groupBox GB_VarTxt_SolutionFolder win=MASPET_PANEL, labelBack=(0,65535,0),pos={xpos_comp+115+330+2,yPos_box3+23},size={12,9}

// save wavenames in solution folder
MPaux_makeWaves4PMF(solutionFOlder,Wavenames)
Wave/T Waves4PMF=$(Solutionfolder+":Waves4PMF")

IF (MStype!=2)	// remove FigTime entry
	Waves4PMF[%FigTimeName]=""
ENDIF

// change wavenote
Note/K Waves4PMF, "Names of Waves used for PMF calculations in folder\r"+ FolderName

// copy idxSample Wave to solution folder
// ! wave name is ALWAYS idxSample !
Make/D/O/N=(dimsize(idxSample_org,0),dimsize(idxSample_org,1)) idxSample=idxSample_org

// copy full explist to solution folder
Make/T/O/N=(numpnts(Explist)) Explist4PMF=ExpList

//-----------------------------------------
// plot stuff
IF (noplot==0)
	// simple itme series
	MPplot_plotPMFtseries(newFolder,nSol,Waves4PMF)
	// factor mass spectra
	MPplot_plotPMFms(newFolder,nSol,Waves4PMF)
ENDIF

//-----------------------------------------
// copy solution space info (last so if something goes wrong it does not matter :-)
Wave/T PMFsolinfo=$(FolderName+":PMFsolinfo" )	// wave in original folder

IF (!Waveexists(PMFsolInfo))
	// prompt user for info
	MPaux_makePMFSolinfo(FolderName)
	Wave/T PMFsolinfo=$(FolderName+":PMFsolinfo" )	// wave in original folder

ENDIF

// copy info data
Make/T/O/N=(numpnts(PMFsolinfo)) $(Solutionfolder+":PMFsolinfo" )
Wave/T PMFsolinfo_sol=$(Solutionfolder+":PMFsolinfo")	// new wave
PMFsolinfo_sol=PMFsolinfo[p]

Variable ii
FOR (ii=0;ii<numpnts(PMFsolinfo_sol);ii+=1)
	labeldummy=Getdimlabel(PMFsolinfo,0,ii)
	Setdimlabel 0,ii,$labelDummy,PMFsolinfo_sol
ENDFOR

END


//======================================================================================
//======================================================================================

// Purpose:		get Tmax values for each factor in each sample 
//					Tmax is peak position of a assym log log fit function
//					PMF solution must be exported with MPpost_getSolution()
// Input:			Scans2D:	wave with factor thermogram data split by sample (output from MPpost_getSolution())
//					Tmax:		Wave with Tmax values from differnet calculations (output from MPpost_getSolution())
// Output:		fitted Tmax values are entered into Tmax Wave
//
// called by:	MPpost_getSolution()	

// NOTE: this is kinda obsolete becasue the same things are calculated with MPpost_getFactorContrib()

FUNCTION MPpost_getTmaxFactor(Scans2D,Tmax)

Wave Scans2D	// matrix with columns: tempSeries, factor thermograms
Wave Tmax		// results Wave: columns: maximum Factor, TMaxFit, half wight -, half width +

// prepare fitting
Make/D/O/N=(4) fitParams=0
Make/FREE/T/O/N=4 constrains=""
Constrains={"K0>0","K1>0","K2>0","K3>0"}
Variable ii
// loop through factors (aka columns in Scans2D)
FOR (ii=0;ii<dimsize(Scans2D,1)-1;ii+=1)
	Make/D/O/N=(dimsize(Scans2D,0)) Thermo,tempSeries
	tempSeries=Scans2D[p][0]
	Thermo=Scans2D[p][ii+1]
	
	WaveStats/Z/Q Thermo
	
	IF (V_maxloc>-1)	// catch flat thermogram
		Tmax[ii][0]=tempSeries[V_maxloc]
		Tmax[ii][4]=1/(273+Tmax[ii][0])// get invers values
		
		Fitparams[0]=V_max
		FitParams[1]=tempSeries[V_maxLoc]
		Fitparams[2]=20
		FitParams[3]=1.1
	
		// do fit
		TRY
			DebuggerOptions debugOnError=0	// turn off debug window
			FuncFit/Q MPaux_asymLogLogNaN, fitParams Thermo /X=tempSeries /C=constrains /NWOK ;AbortOnRTE
			DebuggerOptions debugOnError=1	// turn on debug window
			
			Duplicate/O Thermo,ThermoFit
			ThermoFit=MPaux_asymLogLogNaN(FitParams,ThermoFit,TempSeries)	// calcualte fit line
			// find half width
			Make/D/O/N=2 LevelIdx
			Variable halfAmp=FitParams[0]/2
			Findlevels /P/Q/DEST=LevelIdx ThermoFit, halfAmp 
			//assuming peak shape -> first two level crossings are half width
			
			// store values in Tmax
			Tmax[ii][1]=	fitparams[1]//fitted maximum
			
			Tmax[ii][5]=1/(273+Tmax[ii][1])// get invers values
			
			IF (numpnts(LevelIdx)>0)
				Tmax[ii][2]=fitparams[1]-tempSeries[LevelIdx[0]]
				Tmax[ii][6]=(1/(273+tempSeries[LevelIdx[0]]))-1/(273+fitparams[1])
				IF (numpnts(LevelIdx)>1)	// catch peak too close to end
					Tmax[ii][3]=tempSeries[LevelIdx[1]]-fitparams[1]
					Tmax[ii][7]=1/(273+fitparams[1])-1/(273+tempSeries[LevelIdx[1]])
				ENDIF
			ENDIF
		CATCH
			DebuggerOptions debugOnError=1	// turn on debug window
			
			Variable err= GetRTError(1)
			Tmax[ii][1]=0
			Tmax[ii][5]=0
			
		ENDTRY
	ENDIF
	
ENDFOR

// clean up
Killwaves/Z LevelIdx,Thermo,tempSeries,Fitparams,ThermoFit,temp

END

//======================================================================================
//======================================================================================
// Purpose:		recalculate Cstar values for factor Tmax values
//			

// Input:			SolutionFolder:				String name of active solution folder
//					TmaxCstarCal_values_APP:	Wave with calibration parameters for Tmax->psat (psat=exp(a+b*Tmax))
//					
// Output:		logCstar_split: wave with Tmax values converted to log10(Cstar)
//
// called by:	MPbut_step3_button_control ->  but_recalcTmaxCstar or stand-alone

FUNCTION MPpost_recalcTmaxCstar(SolutionFolder,TmaxCstarCal_values)

String SolutionFolder
Wave TmaxCstarCal_values	// values from APP

SVAR abortStr=root:APP:abortStr
abortStr=""

// check if folder and waves exist
IF (!dataFolderExists(SolutionFolder))
	abortStr="MPpost_recalcTmaxCstar():\r\rgiven active solution folder not found: \r"+SOlutionFolder
	abortStr+="\r\rmake sure to export the solution with 'getSolution' first"
	MPaux_abort(abortStr)
ENDIF

String oldFolder = getdataFolder(1)
Setdatafolder $SolutionFOlder

// check if "FactorContribution" exists -> change VBS into it
String alertStr=""

IF (!datafolderexists("FactorContrib_Tmax"))
	
	IF(datafolderexists("VBS_all"))	// VBS_all folder was found?
		alertStr="The folder 'VBS_all' will be changed to 'FactorContrib_Tmax' in FitPET 1.8. Do you want to convert the existing VBS_all folder (YES) or abort(NO)?"
		DoAlert 1, alertStr
		
		IF (V_FLAG==1)	// yes
			MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
		ELSE	// NO
			abortStr="MPpost_CalcfactorDiurnals():\r\rno folder with name 'FactorContrib_Tmax' found in folder:\r"+SolutionFolder
			abortStr+="\ruser chose abort"
			abort
		ENDIF
	
	ELSE
		// no VBS_all folder
		abortStr="MPpost_CalcfactorDiurnals():\r\rno folder with name 'FactorContrib_Tmax' or 'VBS_all' found in folder:\r"+SolutionFolder
		abortStr+="\ruse 'get solution' in FiTPET or 'getVBS_APP()' to calculate this data"
		MPaux_abort(abortStr)
	ENDIF
	
ENDIF

//update calibration values in solution folder
Wave  calparams=$(SolutionFOlder+":TmaxCstarCal_values")	// values stored with the solution

calparams=TmaxCstarCal_values

// recalculate
Wave MWFactor=avgMWfactor	// signal weighted average MW of each factor
Wave logCstar_split=:FactorContrib_Tmax:logCstar_split
Wave logCstarErr_split=:FactorContrib_Tmax:logCstarErr_split
Wave Tmax_split=:FactorContrib_Tmax:FactorTmax
Wave Tmaxerr_split=:FactorContrib_Tmax:FactorTmaxerr

IF (calparams[0]==0 && calparams[1]==0)
	// both parameters ==0 -> remove logCstar_split
	Killwaves/Z logCstar_split,logCstarErr_split
	
	print "MPpost_recalcTmaxCstar(): Tmax -> psat conversion parameters were 0 => no Cstar values calculated"

ELSE

	// catch if logCstar_split does not exists
	IF (!Waveexists(logCstar_split))
		Make/D/O/N=(dimsize(Tmax_split,0),dimsize(Tmax_split,1)) $(":FactorContrib_Tmax:logCstar_split")
		Make/D/O/N=(dimsize(Tmaxerr_split,0),dimsize(Tmaxerr_split,1),dimsize(Tmaxerr_split,2)) $(":FactorContrib_Tmax:logCstarErr_split")
		Wave logCstar_split=:FactorContrib_Tmax:logCstar_split
		Wave logCstarErr_split=:FactorContrib_Tmax:logCstarErr_split
	ENDIF
	
	// convert Tmax to Cstar
	
	Make/FREE/D/N=(dimsize(logCstar_split,0),dimsize(logCstar_split,1)) psat, psatErr_minus,psatErr_plus,cstarErr_plus,CstarErr_minus
	
	psat=exp(calparams[0] + Tmax_split[p][q]*calparams[1])
	logCstar_split=log(psat*MWFactor[q]/8.314/298*1e6)
	
	psatErr_minus=abs(exp(calparams[0] + (Tmax_split[p][q]+Tmaxerr_split[p][q][0])*calparams[1]))
	psatErr_plus=abs(exp(calparams[0] + (Tmax_split[p][q]+Tmaxerr_split[p][q][1])*calparams[1]))
	
	CstarErr_minus=log(psatErr_minus[p][q]*MWFactor[q]/8.314/298*1e6)
	CstarErr_plus=log(psatErr_plus[p][q]*MWFactor[q]/8.314/298*1e6)
	
	logCstarErr_split[][][0]=abs(logCstar_split[p][q]-CstarErr_minus[p][q])
	logCstarErr_split[][][1]=abs(logCstar_split[p][q]-CstarErr_plus[p][q])

ENDIF

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================

// Purpose:		compare all factor MS or Thermograms from multiple PMF solutions (assuming datastructure from getfactors())
//					using spectral contrast angle
//					1 solutions is compared to multiple others
//					this is the top layer function  for the diffenrt comparison types
//
// Input:			solWaveName:	name of text wve with names of solutions that should be compared
//					sol1Str:		base case for comparison
//					outFolder:	name for result folder (no "root:" but subfolders are possible)
//					type: 		"MS": compare factor mass spectra, "Thermo" compare thermograms, "both" do both
//
// Output:		wave with angles between all spectra in new subfolder
//					image plot translating angles into "goodness of agreement"
//
// called by:	MPbut_step3_button_control ->  but_compareMS or stand-alone

FUNCTION MPpost_comparePMFsolutions(sol1Str,solWavename,outFolder,type)

String sol1Str
String SolWaveName
String outfolder
String type

SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

String oldFolder=getdatafolder(1)

Setdatafolder root:

// get text wave

Wave/T/Z SolWave=$SolWaveName

IF (!Waveexists(SolWave))
	abortStr= "MPpost_comparePMFsolutions():\r\rcannot find wave: " + SolWaveName
	MPaux_abort(abortStr)
ENDIF

Variable nsol=numpnts(SolWave) //number of solutions
IF (nsol==0)
	abortstr="MPpost_comparePMFsolutions():\r\rcomparison wave is empty -> check input"
	MPaux_abort(abortStr)
ENDIF

// loop through Wave to do pairwise comparison
Variable ii

String listOutfolders=""

FOR (ii=0;ii<nsol;ii+=1)

	String sol2Str=SolWave[ii]
	String outfolder1=outfolder+":Comp_"+num2Str(ii)
	
	ListOutFOlders+=outfolder1+";"
		
	// check what to do
	STRSWITCH (type)
	
		CASE "MS":	// compare factor MS
			MPpost_compareFactorMS(sol1Str,sol2str,outFolder1,plot=0)
			BREAK
			
		CASE "Thermo":	// compare thermograms
			MPpost_compareFactorTS(sol1Str,sol2str,outFolder1,plot=0)
			BREAK
			
		CASE "both":	// compare both
			String outFOlderMS=outfolder1+"_MS"
			String outFOlderthermo=outfolder1+"_TS"
			
			MPpost_compareFactorMS(sol1Str,sol2str,outFolderMS,plot=0)
			MPpost_compareFactorTS(sol1Str,sol2str,outFolderThermo,plot=0)
			BREAK
		
		DEFAULT:
			print "MPpost_comparePMFsolutions(): cannot identify comparison type: try again"
			Abort
			
	ENDSWITCH

ENDFOR

//------------------------------
// plot comparison data
Setdatafolder $(outfolder)


Display /W=(516.75,65.75,990,511.25) as "FactorCompare"

// prepare axis positions
Make/FREE /D/N=(nsol,2) axisPos

axisPos[][0]=p*1/nsol
axisPos[][1]=(p+1)*1/nsol

// loop through solutions

FOR (ii=0;ii<nsol;ii+=1)

	String axisName="L"+num2str(ii)
	
	Wave MSangles_temp=$( Stringfromlist(ii,ListOutFOlders) + ":MSangles")
	
	// index for plotting
	Make/D/O/N=(dimsize(MSangles_temp,0)+1) $(Stringfromlist(ii,ListOutFOlders)+":factorIdx1")=p+0.5	// index for plotting
	Make/D/O/N=(dimsize(MSangles_temp,1)+1) $(Stringfromlist(ii,ListOutFOlders)+":factorIdx2")=p+0.5

	Wave factorIDX1=$(Stringfromlist(ii,ListOutFOlders)+":factorIdx1")
	Wave factorIDX2=$(Stringfromlist(ii,ListOutFOlders)+":factorIdx2")
	// plot
	AppendImage/L=$axisName MSangles_temp vs {factorIDX1,FactorIDX2};delayupdate
	
	String CurrentTrace= StringfromList(ii,ImageNameList("",";"))
	
	// set image colour
	ModifyImage $CurrentTrace ctab= {0,30,CyanMagenta,1},minRGB=NaN,maxRGB=(48059,48059,48059);delayupdate

	// set drawing range
	Modifygraph axisEnab($axisName)={axisPos[ii][0],axisPos[ii][1]};delayupdate
	
	
	// draw horizontal lines
	SetDrawEnv ycoord= $axisName,linethick= 2.50;DelayUpdate
	DrawLine 0,0.5,1,0.5;delayupdate
	
	// label
	Label $axisname StringfromList(itemsinlist(solWave[ii],":")-1,solWave[ii],":");delayupdate
	ModifyGraph lblPos($axisname)=60
	Wave factorIDX1=$""
	Wave factorIDX2=$""
	
ENDFOR

// make pretty
Label bottom, StringFromlist(Itemsinlist(sol1str,":")-1,sol1Str,":");delayupdate

ModifyGraph tick=2,mirror=1,fStyle=1,fSize=16,axThick=2,standoff=0,freePos=0,grid=1,gridHair=1,gridRGB=(0,0,0);delayupdate

// colour scale
ColorScale/C/N=text0/F=0/B=1/D={1,1,0}/A=RB/X=0.5/Y=1.5 vert=0,widthPct=50,image=MSangles,axisRange={0,32},fstyle=1,tickThick=2.00,ZisZ=1;DelayUpdate
ColorScale/C/N=text0 "contrast angle / degree";delayupdate

Setdatafolder $oldFolder

END


//================================================
//================================================

// Purpose:		compare the factor mass spectra of two solutions
// Input:			sol1Srt:		String with name of first solution
//					sol2Str:		String with name of second solution
//					outFOlder:	String with name for results from comparison
//					[plot]:		0: do not create a plot, 1: create plot of comparison	
// Output:		if plot=1 grid plot of comparison
// called by:	MPpost_comparePMFsolutions()

FUNCTION MPpost_compareFactorMS(sol1Str,sol2str,outFolder[,plot])

String sol1Str,sol2str,outFolder
Variable plot

IF (ParamIsDefault(plot))
	plot=1
ENDIF

SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// prepare results folder
setdatafolder root:

// check input folders
IF(!datafolderexists(sol1Str))
	abortSTr ="MPpost_compareFactorMS():\r\rcan't find folder: \r"+sol1Str + "\r\rHint: you must use the full path to the folder"
	MPaux_abort(abortStr)
ENDIF
IF(!datafolderexists(sol2Str))
	abortSTr= "MPpost_compareFactorMS():\r\rcan't find folder: "+sol2Str+ "\r\rHint: you must use the full path to the folder"
	MPaux_abort(abortStr)
ENDIF

// get data for each folder
// find out how many factors
Setdatafolder sol1Str // first solution

// check if old export data is there
Variable WaveCheck=MPaux_check4FitPET_MSTS(sol1Str)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_compareFactorMS():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() + " "+ time() + "\tComparing factor mass spectra:"
	print "\t+Check Wavenames in folder: "+sol1Str
	print "\t\texpected Wavenames for "
	print "\t\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_compareFactorMS():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=sol1Str
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

String profileList=Wavelist("Factor_TS*",";","")
profileList=removeFromList("Factor_TS_scaled",profileList)	// remove FacorThermo_Scaled from list

Variable pp, nof1=itemsinlist(profileList)	// number of factors

IF (nof1<=0)	// catch if no waves were found
	abortSTr ="MPpost_compareFactorMS():\r\rno waves with name Factor_TS* found in folder "+sol1Str 
	MPaux_abort(abortStr)
ENDIF

// prepare matrix for data (one column for each factor)
Wave/D tempFactor1=$("Factor_MS1")

Make/FREE/D/N=(numpnts(tempFactor1),nof1) FactorMatrix1

FOR (pp=0;pp<nof1;pp+=1)
	
	// get factor
	Wave/D tempFactor1=$("Factor_MS"+num2str(pp+1))	// factor count starts from 1
	// put into matrix
	FactorMatrix1[][pp]=tempFactor1[p]
	
ENDFOR

Setdatafolder sol2Str // second solution

// check if old export data is there
WaveCheck=MPaux_check4FitPET_MSTS(sol2Str)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_compareFactorMS():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() + " "+ time() + "\tComparing factor mass spectra:"
	print "\t+ Check Wavenames in folder: "+sol2Str
	print "\t\texpected Wavenames for "
	print "\t\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\T\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_compareFactorMS():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=sol2Str
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

profileList=Wavelist("Factor_TS*",";","")
profileList=removeFromList("Factor_TS_scaled",profileList)	// remove FacorThermo_Scaled from list

Variable nof2=itemsinlist(profileList)	// number of factors

IF (nof2<=0)	// catch if no waves were found
	abortSTr ="MPpost_compareFactorMS():\r\rno waves with name Factor_TS* found in folder "+sol2Str 
	MPaux_abort(abortStr)
ENDIF

// prepare matrix for data (one column for each factor)
Wave/D tempFactor2=$("Factor_MS1")

IF (numpnts(tempFactor2) != numpnts(tempFactor1))	// check number of ions in spectra
	abortSTr = "MPpost_compareFactorMS():\r\rdifferent number of ions in datasets"
	MPaux_abort(abortStr)
ENDIF

Make/FREE/D/N=(numpnts(tempFactor2),nof2) FactorMatrix2

FOR (pp=0;pp<nof2;pp+=1)
	
	// get factor
	Wave/D tempFactor2=$("Factor_MS"+num2str(pp+1))	// factor count starts from 1
	// put into matrix
	FactorMatrix2[][pp]=tempFactor2[p]
	
ENDFOR

//-----------------------
//  get angles for each pair
Variable ff
String SubName=""
Setdatafolder root:

FOR (ff=1;ff<Itemsinlist(outFOlder,":");ff+=1)	// catch subfolders
	newdatafolder/O/S $(Stringfromlist(ff,outfolder,":"))
	
ENDFOR

Make/O/D/N=(nof1,nof2) MSangles=NaN
Note MSangles, "spectral contrast angles between MS vectors\rrows from solution: "+sol1Str+"\rcolumns from solution: "+sol2Str

// make info about solutions
Make/T/O/N=2 ComparedSolutions={sol1Str,sol2Str}


Make/FREE/D/N=(dimsize(FactorMatrix1,0)) tempFactor1,tempFactor2

Variable ff1,ff2
FOR (ff1=0;ff1<nof1;ff1+=1)	// row counter, loop through factors in solution 1

	FOR(ff2=0;ff2<nof2;ff2+=1)	// column counter loop through solutions in factor 2
		// pick factors
		tempFactor1=FactorMatrix1[p][ff1]
		tempFactor2=FactorMatrix2[p][ff2]
		// calculate angles
		MPpost_calcMSangle(tempFactor1,tempFactor2,"thetaTemp",quiet=1)
		
		Wave Theta=ThetaTemp
		MSangles[ff1][ff2]=theta[0]
		
	ENDFOR

ENDFOR

//------------------------
// plot results
// make colour table for goodness of agreement

IF (plot)
	MPpost_plotContrastAngle("MSangles")
ENDIF

END

//=================================================

// Purpose:		compare the factor thermograms of two solutions
//					!!!! currently not used !!!
// Input:			sol1Srt:		String with name of first solution
//					sol2Str:		String with name of second solution
//					outFOlder:	String with name for results from comparison
//					[plot]:		0: do not create a plot, 1: create plot of comparison	
// Output:		if plot=1 grid plot of comparison
// called by:	MPpost_comparePMFsolutions()


FUNCTION MPpost_compareFactorTS(sol1Str,sol2str,outFolder[,plot])

String sol1Str,sol2str,outFolder
Variable plot

IF (ParamIsDefault(plot))
	plot=1
ENDIF

SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// prepare results folder
setdatafolder root:

// check input folders
IF(!datafolderexists(sol1Str))
	abortstr= "MPpost_compareFactorTS():\r\rcannot find folder: "+sol1Str
	MPaux_abort(abortStr)
ENDIF
IF(!datafolderexists(sol2Str))
	abortstr= "MPpost_compareFactorTS():\r\rcannot find folder: "+sol2Str
	MPaux_abort(abortStr)
ENDIF

// get data for each folder
//find out how many factors
Setdatafolder sol1Str // first solution

// check if old export data is there
Variable WaveCheck=MPaux_check4FitPET_MSTS(sol1Str)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_compareFactorMS():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() + " "+ time() + "\tComparing factor mass spectra:"
	print "\t+ Check Wavenames in folder: "+sol1Str
	print "\t\texpected Wavenames for "
	print "\t\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_compareFactorMS():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=sol1Str
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

String profileList=Wavelist("Factor_TS*",";","")
Variable pp, nof1=itemsinlist(profileList)	// number of factors

IF (nof1<=0)	// catch if no waves were found
	abortstr= "MPpost_compareFactorTS():\r\rno waves with name Factor_TS* found in folder "+sol1Str 
	MPaux_abort(abortStr)
ENDIF

// prepare matrix for data (one column for each thermogram)
Wave/D tempFactor1=$("Factor_TS1")

Make/FREE/D/N=(numpnts(tempFactor1),nof1) ThermoMatrix1

FOR (pp=0;pp<nof1;pp+=1)
	
	// get factor
	Wave/D tempFactor1=$(stringfromlist(pp,profileList))
	
	//normalise to sum
	//Variable total=sum(tempFactor1)
	Variable scalingFac=WaveMax(tempFactor1)
	//
	scalingFac=1
	// put into matrix
	ThermoMatrix1[][pp]=tempFactor1[p]/scalingFac
	
ENDFOR

Setdatafolder sol2Str // second solution

// check if old export data is there
WaveCheck=MPaux_check4FitPET_MSTS(sol2Str)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_compareFactorMS():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() + " "+ time() + "\tComparing factor mass spectra:"
	print "\t+ Check Wavenames in folder: "+sol2Str
	print "\t\texpected Wavenames for "
	print "\t\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_compareFactorMS():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=sol2Str
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

profileList=Wavelist("Factor_TS*",";","")
Variable nof2=itemsinlist(profileList)	// number of factors

IF (nof2<=0)	// catch if no waves were found
	abortstr= "MPpost_compareFactorTS():\r\rno waves with name Factor_TS* found in folder "+sol2Str 
	MPaux_abort(abortStr)
ENDIF

// prepare matrix for data (one column for each thermogram)
Wave/D tempFactor2=$("Factor_TS1")

IF (numpnts(tempFactor2) != numpnts(tempFactor1))	// check number of ions in spectra
	print "MPpost_compareFactorTS():\r\rdifferent number of ions in datasets"
	abort
ENDIF

Make/FREE/D/N=(numpnts(tempFactor2),nof2) ThermoMatrix2

FOR (pp=0;pp<nof2;pp+=1)
	
	// get factor
	Wave/D tempFactor2=$(Stringfromlist(pp,profileList))	// factor count starts from 1
	
	//normalise to sum
	//total=sum(tempFactor2)
	scalingFac=WaveMax(tempFactor2)
	scalingFac=1
	
	// put into matrix
	ThermoMatrix2[][pp]=tempFactor2[p]/scalingFac
	
ENDFOR

//-----------------------
//  get angles for each pair
Variable ff
String SubName=""
Setdatafolder root:
FOR (ff=0;ff<Itemsinlist(outFOlder,":");ff+=1)	// catch subfolders
	newdatafolder/O/S $(Stringfromlist(ff,outfolder,":"))
	
ENDFOR

Make/O/D/N=(nof1,nof2) MSangles=NaN
Note MSangles, "spectral contrast angles between MS vectors\rrows from solution: "+sol1Str+"\rcolumns from solution: "+sol2Str

// make info about solutions
Make/T/O/N=2 ComparedSolutions={sol1Str,sol2Str}

Make/FREE/D/N=(dimsize(ThermoMatrix1,0)) tempFactor1,tempFactor2

Variable ff1,ff2
FOR (ff1=0;ff1<nof1;ff1+=1)	// row counter, loop through factors in solution 1

	FOR(ff2=0;ff2<nof2;ff2+=1)	// column counter loop through solutions in factor 2
		// pick factors
		tempFactor1=ThermoMatrix1[p][ff1]
		tempFactor2=ThermoMatrix2[p][ff2]
		// calculate angles
		MPpost_calcMSangle(tempFactor1,tempFactor2,"thetaTemp",quiet=1)
		
		Wave Theta=ThetaTemp
		MSangles[ff1][ff2]=theta[0]
		
	ENDFOR

ENDFOR

//------------------------
// plot results
// make colour table for goodness of agreement
IF (plot)
	MPpost_plotContrastAngle("MSangles")
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		plot the results from MPpost_compareFactorMS() or compareFactorTS()
//
// Input:			MSangleStr:	String name of Wave with contrast angles calculated by compareFactorMS() or compareFactorTS()
// Output:		grid plot of comparison
// called by:	MPpost_comparePMFsolutions() -> MPpost_compareFactorMS() or MPpost_compareFactorTS()


FUNCTION MPpost_plotContrastAngle(MSanglesStr)

String MSanglesStr	// string name for wave with contrast angles 

// get waves
Wave MSangles=$MSanglesStr

IF (!waveexists(Msangles))	// no wave found
	String abortStr="MPpost_plotContrastAngle():\r\rWave: '"+ MSanglesStr+"' not found in folder: "+	getdatafolder(1)
	MPaux_abort(abortStr)
ENDIF

// plot image
Make/D/O/N=(dimsize(msangles,0)+1) factorIdx1=p+0.5
Make/D/O/N=(dimsize(msangles,1)+1) factorIdx2=p+0.5

Display /W=(516.75,65.75,990,511.25) as "FactorCompare"
AppendImage MSangles vs {factorIDX1,FactorIDX2}

ShowInfo

// make graph pretty
// Get  axis labels from MSangles note
String FullNote=Note(MSangles)
String sol1Str=Stringfromlist(1,Stringfromlist(1,fullNote,"\r"),": ")
String sol2Str=Stringfromlist(1,Stringfromlist(2,fullNote,"\r"),": ")

Label bottom, sol1Str
Label left, sol2Str

ModifyGraph tick=2,mirror=1,fStyle=1,fSize=16,axThick=2,standoff=0

ModifyImage MSangles ctab= {0,30,CyanMagenta,1},minRGB=NaN,maxRGB=(48059,48059,48059)

// colour scale
ColorScale/C/N=text0/F=0/B=1/D={1,1,0}/A=RB/X=0.5/Y=1.5 vert=0,widthPct=50,image=MSangles,axisRange={0,32},fstyle=1,tickThick=2.00,ZisZ=1;DelayUpdate
ColorScale/C/N=text0 "contrast angle / degree"

END

//======================================================================================
//======================================================================================

// Purpose:		calculate the "angle" between two mass spectra
//					
// Input:			MS1,MS2:	two mass spectra to compare (must have same length)
//					out:		string to name output wave
//			 		[quiet]:	1: no output in history
// Output:		wave with name out containing the angle value in degree
// called by:	MPpost_comparePMFsolutions() -> MPpost_compareFactorMS() or MPpost_compareFactorTS()	

FUNCTION MPpost_calcMSangle(MS1, MS2, out [,quiet])

Wave MS1,MS2	// mass spec data (must have same length)
String out	// name for result wave
Variable quiet

IF (PARAMIsDefault(quiet))
	quiet=0
ENDIF

IF (numpnts(MS1) != numpnts(MS2))
	print "MPpost_calcMSangle(): the two MS waves have different number of points"
	abort
ENDIF

DUPLICATE/O/Free MS1, dotProduct, lengthMS1,lengthMS2,tempMS1,tempMS2

tempMS1=MS1
tempMS2=MS2

// calculate MS1 dot MS2 (scalar product)
dotProduct=tempMS1*tempMS2	// a1*b1,...,a10*b10

// calculate vector length
lengthMS1=tempMS1*tempMS1	// a1*a1,... ,a10*a10
lengthMS2=tempMS2*tempMS2

Variable absMS1=	 sum(lengthMS1)// sum of a1*a1, ... ,a10*a10
Variable absMS2=	 sum(lengthMS2)

Make/D/O/N=1 $(out)

Wave theta=$(out)

theta=acos(sum(dotProduct)/(sqrt(absMS1)*sqrt(absMS2)))	// inverse cosinus
theta*=180/pi	// convert radians to degree
Note theta, "angle between two mass spectra in degree"

// screen output
IF(quiet!=1)
	print "dot product: "+num2str(sum(dotProduct))

	print "length MS1: "+num2str(sqrt(absMS1))
	print "length MS2: "+num2str(sqrt(absMS2))
	
	print "cos(theta)="+num2str(sum(dotProduct)/(sqrt(absMS1)*sqrt(absMS2)))
	print "theta= "+num2str(theta[0])+"°"
	IF (sum(dotProduct)/(sqrt(absMS1)*sqrt(absMS2))>1)
		print "cos(theta) is larger than 1"
	ENDIF
ENDIF

END


//======================================================================================
//======================================================================================

// Purpose:	compare un/scaled residuals for multiple solutions
//				solutions must have been exported with MPpost_getSolution()
// Input:		solutionFolder:	string name of active solution folder
//				CompWaveName:	string name of txt wave with solutions to compare to
//				wavenames:		txt wave with names of data waves
//				type:				0: as time series, 1: as mass spectra
// Output:	plot with unscaled, relative and scaled residuals for the given solutions
// called by: MPbut_step3_button_control -> but_compareResidual_tseries

FUNCTION MPpost_comparePMFresidual(solutionFolder,CompWavename,wavenames,type)

String solutionfolder
String Compwavename
Wave/T wavenames
Variable type

// get abort Str
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

String oldFolder=getdatafolder(1)

Setdatafolder root:

// check solution folder
IF(!datafolderExists(solutionFOlder))
	abortStr="MPpost_comparePMFresidual():\r\rcannot find active solution folder:\r" + SolutionFolder
	abortStr+="\rcheck active solution name in Panel"
	MPaux_abort(abortStr)
ENDIF

IF (!Waveexists($(solutionfolder+":Q_Qexp_tseries")))	// folder exists but does not have the right waves
	abortStr="MPpost_comparePMFresidual():\r\rcannot find wave: \r"+solutionfolder+":Q_Qexp_tseries"
	abortSTr+="\rmake sure the solutions were exported with 'get solution' button from Panel"
	MPaux_abort(abortStr)
ENDIF

// get text wave with solutions
Wave/T SolWave=$CompWavename

// checks for solution wave
IF (!Waveexists(SolWave))	// exists?
	abortStr= "MPpost_comparePMFresidual():\r\rcannot find wave: \r" + Compwavename
	MPaux_abort(abortStr)
ENDIF

Variable nsol=numpnts(SolWave) //number of entries
IF (nsol==0)
	abortstr="MPpost_comparePMFresidual():\r\rcomparison wave is empty -> check input"
	MPaux_abort(abortStr)
ENDIF

// check for colour wave
Wave/D COlourwave=root:APP:colourwave
IF (!waveexists(Colourwave))
	MPplot_makeColourWave()
	Wave/D COlourwave=root:APP:colourwave
ENDIF

// set names according to type
String NameXwave,Nameywave1,Nameywave2,Nameywave3
String PlotName
String SolutionName=stringfromlist(Itemsinlist(solutionfolder,":")-1,solutionfolder,":")

IF (type==0)
	NameXwave=":"+Wavenames[%Tname]
	Nameywave1=":ResidualAbs_tseries"
	Nameywave2=":ResidualRel_tseries"
	Nameywave3=":Q_Qexp_tseries"
	PlotName="Residual_tseries_"+solutionName
ELSE
	NameXwave=":"+Wavenames[%MZname]
	Nameywave1=":ResidualAbs_MS"
	Nameywave2=":ResidualRel_MS"
	Nameywave3=":Q_Qexp_MS"
	PlotName="Residual_MS_"+solutionName
ENDIF

// plot active solution

Killwindow/Z $plotName
Display/W=(50,20,550,620) as plotName
Dowindow /C $plotName

String legendStr=""
String CurrentTrace=""
String tracelist=""
String legStr=""
String xlabelStr="ion mass"

Wave xwave=$(solutionfolder+NameXwave)
Wave ywave1=$(solutionfolder+Nameywave1)
Wave ywave2=$(solutionfolder+Nameywave2)
Wave ywave3=$(solutionfolder+Nameywave3)

// unscaled residual
appendtograph/L=L1 ywave1 vs xwave
traceList=Tracenamelist("",";",1)
currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
ModifyGraph rgb($currentTrace)=(colourwave[0][0],colourwave[0][1],colourwave[0][2])

// legendstr entry
legStr+="\s("+currentTrace+") "+solutionName+"\r"

// relative unscaled residual
appendtograph/L=L2 ywave2 vs xwave
traceList=Tracenamelist("",";",1)
currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
ModifyGraph rgb($currentTrace)=(colourwave[0][0],colourwave[0][1],colourwave[0][2])

// scaled residual
appendtograph/L=L3 ywave3 vs xwave
traceList=Tracenamelist("",";",1)
currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
ModifyGraph rgb($currentTrace)=(colourwave[0][0],colourwave[0][1],colourwave[0][2])

// loop through other solutions
Variable ff
Variable ColourIdx
VAriable test=1
String InfoStr="\t\tresidual waves missing for solutions:"


FOR (ff=0;ff<nsol;ff+=1)
	
	String currentfolder=SolWave[ff]	// folder path for currrent solution
	String currentsolution	=stringfromlist(Itemsinlist(currentfolder,":")-1,currentFOlder,":")//"name" of current solution (use last folder in path)
	
	// catch if active solution is part of compwave -> skip
	IF (stringmatch(solutionfolder,currentFOlder)==0)
		// get waves for plotting
		Wave xwave=$(currentfolder+NameXwave)
		Wave ywave1=$(currentfolder+Nameywave1)
		Wave ywave2=$(currentfolder+Nameywave2)
		Wave ywave3=$(currentfolder+Nameywave3)
	
		IF (waveexists(xwave) && waveexists(ywave1)&& waveexists(ywave2)&& waveexists(ywave3))
			// check colouridx
			ColourIdx=ff+1	// skip one for active solution
			IF (ff>= dimsize(colourwave,0))
				colourIDX=ff-dimsize(colourwave,0)
			ENDIF
			
			// unscaled residual
			appendtograph/L=L1 ywave1 vs xwave
			
			traceList=Tracenamelist("",";",1)
			currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
			ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
			
			// legendstr entry
			legStr+="\s("+currentTrace+") "+currentsolution+"\r"
	
			// relative unscaled residual
			appendtograph/L=L2 ywave2 vs xwave
			traceList=Tracenamelist("",";",1)
			currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
			ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
			
			// scaled residual
			appendtograph/L=L3 ywave3 vs xwave
			traceList=Tracenamelist("",";",1)
			currentTrace=Stringfromlist(itemsinlist(traceList)-1,traceList)
			ModifyGraph rgb($currentTrace)=(colourwave[colourIDX][0],colourwave[colourIDX][1],colourwave[colourIDX][2])
			
			test+=1
			
			// set label for x axis
			IF (type==0 )
				IF (xwave[0]<3e8)
					xlabelStr="data index"
				ELSE
					xlabelStr="time"
				ENDIF
			ENDIF

		ELSE
		
			InfoStr+="\r\t\t"+currentFolder
		
		ENDIF	
	ELSE
		test+=1
	ENDIF
ENDFOR	// solution loop

// make pretty
Modifygraph lsize=2

ModifyGraph tick=2,mirror=1,fStyle=1,axThick=2,lowTrip=0.01,standoff=0

ModifyGraph zero(L1)=4,nticks(L1)=3,ZisZ(L1)=1,freePos(L1)={0,kwFraction},lblPos(L1)=60
ModifyGraph zero(L2)=4,nticks(L2)=3,ZisZ(L2)=1,freePos(L2)={0,kwFraction},lblPos(L2)=60
ModifyGraph zero(L3)=4,nticks(L3)=3,ZisZ(L3)=1,freePos(L3)={0,kwFraction},lblPos(L3)=60

ModifyGraph axisEnab(L1)={0.66,1},axisEnab(L2)={0.33,0.66},axisEnab(L3)={0,0.33}

// change to sticks with marker for MS
IF (type==1)
	MOdifyGraph mode=8,lsize=1
ENDIF

// axis labels
Label bottom, xlabelStr
Label L1, "unscaled residual"
Label L2, "relative residual"
Label L3, "Q/Q\Bexp"

// draw line
SetDrawLayer UserBack

SetDrawEnv linethick= 2.50
DrawLine 0,0.67,1,0.67
SetDrawEnv linethick= 2.50
DrawLine 0,0.34,1,0.34

	
// set legend
legStr=removeending(legstr,"\r")
Legend/LT LegStr


// inform user about missing solutions
IF (test<(nsol+1))	// at least one entry not found
	String typeStr="mass spectra"
	IF (type==0)
		typeStr="time series"
	ENDIF
	print "-----------------"
	print date() +" "+time()+": comparing residuals as "+typeStr
	print "\t+ MPpost_comparePMFresidual(): at least one of the selected solutions was missing"
	print infoStr
ENDIF

setdatafolder $oldFOlder

END

//======================================================================================
//======================================================================================

// Purpose:	wrapper routine for MPpost_getFactorContrib()
//				create necessary index waves etc.
//				PMF data must exist and exported with MPpost_getsolution()
// Input:		folderStr:	name of Folder with PMF results for one solution 
//								this must be the full path including "root:"
//				expliststr:	text wave with names of scans (eg. lowOC_00RTC)
//				onlyGood:		1: use only "good" factors, 0:use all factors
//				CalParams:	Wave with calibration parameters for Tmax->psat (psat=exp(a+b*Tmax))
//				MStype:		what type of data (2: Fig TD)
//				[quiet]:		1: no plot
// Output:	FactorContrib_abs:		contributino of each factor in each sample
//				FactorContrib_rel:		scaled to total signal for each sample
//				FactorTmaxI:		TMax values
//				FactorTmaxI		1/Tmax
//				Tmaxerr_split	error of Tmax as halfwidth of factor thermograms
//				TmaxIerr_split:	inverse Tmax error
//						
// called by: MPbut_Step3_button_Control -> but_getSolution


FUNCTION MPpost_CalcFactorContrib(folderStr,expliststr,onlyGood,CalParams,MSType[,quiet])

String folderStr		// name of results folder to operate on
String explistStr	// name of text wave with sample names
Variable onlyGood	// run with all factors or with "good" ones
Wave CalParams		// Wave with parameters for Tmax->Cstar
Variable MStype
Variable quiet		//1: no plot

Variable noplot
IF (paramisdefault(quiet))
	noplot=0
ELSE
	noplot=quiet
ENDIF

setdatafolder root:

SVAR/Z abortStr=root:app:abotrStr

IF (!Svar_Exists(AbortStr))
	String /G abortStr
ENDIF

// check for data
IF (!waveexists($(folderstr+":factor_MS1")))
	abortStr="MPpost_CalcFactorContrib():\r\rno PMF data found in folder: "+"root:"+folderstr+":factor_MS1"
	abortStr+="\rcheck input and export PMF results with 'MPpost_getSolution()'"
	MPaux_abort(abortStr)
ENDIF

setdatafolder $(folderStr)

// determine number of factors
Setdatafolder :DataSortedBySample
String ListOfWaves=Wavelist("*_Tmax",";","")
SetDatafolder ::

IF (Itemsinlist(listOfWaves)==0)
	abortStr="MPpost_CalcFactorContrib():\r\rno wave with name '*_Tmax' found in folder:\r"+folderstr
	MPaux_abort(abortStr)
ENDIF

Wave TmaxWave=$(":DataSortedBySample:"+stringfromlist(0,ListofWaves))	// pick first one to check factor number

Variable nof=dimsize(TmaxWave,0)

Wave/T ExpList=$(explistStr)
Variable noe=numpnts(explist)	// number of experiments

IF (!Waveexists(expList))
	abortStr="MPpost_CalcFactorContrib():\r\rno wave found with name: root:"+explistStr
	MPaux_abort(abortStr)

ENDIF

// create factorList and IntIdx
make/D/O/N=(nof) FactorList_all=p+1

Make /D/O/N=(nof,2,noe)	IntIdx_all=0

Variable ee
FOR (ee=0;ee<noe;ee+=1	)// loop through experiments to get length of Tseries
	Wave TestWave=$(":DataSortedBySample:"+expList[ee]+"_TS")
	IntIdx_all[][1][ee]=dimsize(TestWave,0)-1	
	Wave TestWave=$""
ENDFOR

// get factor contribution calculated for all factors
MPpost_getFactorContrib(folderStr,"FactorContrib_Tmax",FactorList_all,IntIdx_all,ExpListStr,noplot,calParams,MSType)

END

//======================================================================================
//======================================================================================

// Purpose:		calculate Factor contributions and do Tmax fit for each sample, 
//					calculate Factor area and split up factors if needed
//					fit each factor thermogram with a asym loglog function and store Tmax
//					store Tmedian, T25, T75
// Input:			
//					folderStr:	name of Folder with PMF results for one solution ("combi_F7")
//					resultFolderStr:	name for subfolder with VBS results
//					Factorlist:	Wave with number of factor (sort in intended order, for split factors give same number twice)
//					IntIdx:		Wave with start and endpoint for integration (layer for each experiment
// 					ExpListName:	text wave with names of scans (eg. lowOC_00RTC)
//					quiet:			1: no plot
//					CalParams:	Wave with calibration parameters for Tmax->psat (psat=exp(a+b*Tmax))
//					MStype:		data type (2 is FIG TD)
//					doTmax[optional]:	1: calcaulate Tmax and Tmedian values, 0: skip that calcaulation
//
// Output:		FactorContrib_abs:	contributino of each factor in each sample
//					FactorContrib_rel:	scaled to total signal for each sample
//					FactorTmaxI:		TMax values
//					FactorTmaxI		1/Tmax
//					Tmaxerr_split	error of Tmax as halfwidth of factor thermograms
//					TmaxIerr_split:	inverse Tmax error
//				
// called by:	MPpost_calcFactorContrib()


FUNCTION MPpost_getFactorContrib(folderPath, resultFolderStr,FactorList,IntIdx,ExpListName,quiet,calParams,MStype,[doTmax])

String folderPath,ExpListName,resultFolderStr
Wave FactorList,IntIdx
Variable quiet
Wave calParams
Variable MStype
Variable doTmax

// set default for optional
IF(paramIsDefault(doTmax))	// default is =1 -> do Tmax fit
	doTmax=1
ENDIF

// check dimensions of factor list and index wave
IF(numpnts(factorlist)!=dimsize(intIdx,0))
	print "MPpost_getFactorContrib(): number of rows in factorList and IntIdx waves do not match"
	abort
ENDIF

// go to right folder
Setdatafolder $folderPath

// get experiment List
Wave/T ExpList=$(ExpListName)

// prepare new waves in vbs subfolder
newdatafolder/O/S $resultFolderStr

Make/D/O/N=(numpnts(explist),numpnts(FactorList)) FactorContrib_rel,FactorContrib_abs,FactorTmax,FactorTmaxI,FactorTmedian
//VBS_split, TmaxI_split,Tmax_split

Make/D/O/N=(numpnts(explist),numpnts(FactorList),2) FactorTmaxIerr,FactorTmaxErr,FactorTmedianErr // columns for plus minus error

Note/K FactorContrib_abs
Note/K FactorTmaxI, "inverse T (K^-1) from fit"
Note/K FactorTmax, "Tmax (C) from fit\r"
Note/K FactorTmaxIerr,"uncertainty estimated from halfwidth of fitted curve\rfirst layer:negative error;second layer: positive error\r"
Note/K FactorTmaxErr,"uncertainty estimated from halfwidth of fitted curve\rfirst layer:negative error;second layer: positive error\r"
 
Note/K FactorTmedian,"Tmedian (C)"
Note/K FactorTmedianErr,"first layer:Tmedian-T25;second layer:T75-Tmedian"

//check if logCstar can be calculated
Variable DoCstar=0
IF (calparams[0]!=0 || calparams[1]!=0)
	doCstar=1
	Make/D/O/N=(numpnts(explist),numpnts(FactorList)) logCstar_split
	Make/D/O/N=(numpnts(explist),numpnts(FactorList),2)logCstarErr_split	
	Note/K logCstar_split
ELSE
	// remove existing waves
	Wave/Z logCstar_split=logCstar_split
	Wave/Z logCstarErr_split,logCstarErr_split
	Killwaves/Z logCstar_split,logCstarErr_split
	
ENDIF

// go back up one datafolder
setdatafolder ::

Variable ee, ff
String TmaxName=""
String ScanName=""
String CstarName=""
String labelDummy=""

Make/D/O/N=4 fitparams
Make/FREE/T/O/N=4 constrains=""
Constrains={"K0>0","K1>0","K2>0","K3>0"}

// loop through experiments
FOR (ee=0;ee<numpnts(expList);ee+=1)
	// get data
	ScanName=":DataSortedBySample:"+expList[ee]+"_TS"
	TmaxName=":DataSortedBySample:"+expList[ee]+"_Tmax"
	
	Wave Scans= $(ScanName)
	Wave Tmax=$(TmaxName)

	// set labels in waves
	labeldummy=expList[ee]
	
	Variable maxLength=254
	IF (Igorversion()<8.0)	// catch too long names
		maxLength=31
	ENDIF
	IF (strlen(labelDummy)>maxLength)
		LabelDummy="S_"+num2str(ee)
	ENDIF
	
	SetDimlabel 0,ee,$Labeldummy,FactorContrib_abs,FactorContrib_rel,FactorTmax,FactorTmedian
		
	
	// loop through factors
	FOR (ff=0;ff<numpnts(FactorList);ff+=1)
		
		Variable Fidx=FactorList[ff]	// current Factor number
		
		IF (IntIdx[ff][1][ee]>dimsize(Scans,0))	// check for end index being larger than scans wave
			IntIdx[ff][1][ee]=dimsize(Scans,0)-1
		ENDIF	
				
		Variable length =IntIdx[ff][1][ee]-IntIdx[ff][0][ee]
		IF (length<=0)
			length = dimsize(Scans,0)-1
		ENDIF
		Make/D/O/N=(length) TempF, TempT	// temporary waves with slice of data

		tempF=Scans[p+IntIdx[ff][0][ee]][Fidx]	// get current Factor
		tempT=Scans[p+IntIdx[ff][0][ee]][0]		// temperature series
		
		// check if selected wave contains points
		IF (numpnts(tempF)==0)
			String errStr="MPpost_getFactorContrib(): no points for F"+num2str(Fidx)+" in experiment "+expList[ee] + " found with given intervals -> using full range"
			print errStr
			tempF=Scans[p][Fidx]	// get current Factor
			tempT=Scans[p][0]		// temperature series				
		ENDIF
		
		// make note about which factor
		IF (ee==0)
			// wave notes
			Note/NOCR FactorContrib_abs "F"+num2str(Fidx)+"; "
			Note/NOCR FactorTmaxIErr "F"+num2str(Fidx)+"; "
			Note/NOCR FactorTmax "F"+num2str(Fidx)+"; "
			Note/NOCR FactorTmaxErr "F"+num2str(Fidx)+"; "
			Note/NOCR FactorTmaxI "F"+num2str(Fidx)+"; "
			IF (doCstar==1)
				Note/NOCR logCstar_split "F"+num2str(Fidx)+"; "
			ENDIF
			
			// wavelabels
			LabelDummy="F"+num2str(Fidx)
			SetDimlabel 1,ff, $Labeldummy,FactorContrib_abs,FactorContrib_rel,FactorTmax,FactorTmedian
		ENDIF

		//----------------------------------------
		// get area with bounds from index wave
		integrate/METH=1 tempF /X=tempT /D=FareaTemp
		FactorContrib_abs[ee][ff]=FareaTemp[numpnts(FareaTemp)-1]	
				
		//----------------------------------------
		// Get Tmax and Tmedian -> only for FIG TD

		IF (MStype==2 && doTmax==1)
			//----------------------------------------
			// get t median values from area under thermogram
			
			Findlevel/Q FareaTemp,FareaTemp[numpnts(FareaTemp)-1]*0.5
			FactorTmedian[ee][ff]=tempT[round(V_LevelX)]
			
			FindLevel/Q FareaTemp,FareaTemp[numpnts(FareaTemp)-1]*0.25
			FactorTmedianerr[ee][ff][0]=FactorTmedian[ee][ff]-tempT[round(V_LevelX)]
			
			FindLevel/Q FareaTemp,FareaTemp[numpnts(FareaTemp)-1]*0.75
			FactorTmedianerr[ee][ff][1]=tempT[round(V_LevelX)]-FactorTmedian[ee][ff]

			//----------------------------------------
			// get Tmax from fit
			
			// fit with bounds from index wave
			WaveStats/Z/Q tempF
					
			IF (V_maxLoc>-1)	// catch thermogram being completely 0
				// check is Max is spike at start
				IF (V_maxLoc<2)	// highest point is within first 2 data points
	
					IF(tempF[V_maxLoc]>10*tempF[V_maxLoc+10])	// check for very steep spike
						// redo wavestats without start part
						Wavestats/Q/R=[10,numpnts(tempF)-1] tempF
					ENDIF
				
				ENDIF
				
				// set values
				Fitparams[0]=V_max
				FitParams[1]=tempT[V_maxLoc]
				Fitparams[2]=20
				FitParams[3]=1.1
			
				// do fit
				TRY
					DebuggerOptions debugonerror=0
					FuncFit/Q/N=1 MPaux_asymLogLogNaN, fitParams tempF /X=tempT /C=constrains /NWOK ;AbortOnRTE
					DebuggerOptions debugonerror=1
								
					// get half width for error
					Duplicate/O tempF,tempF_Fit
					tempF_Fit=MPaux_asymLogLogNaN(FitParams,tempF_Fit,tempT)	// calculate fit line
					
					Make/D/O/N=2 LevelIdx
					Variable halfAmp=FitParams[0]/2
					Findlevels /P/Q/DEST=LevelIdx tempF_Fit, halfAmp 
					
					// halfwidth
					variable errP,errN,errIN,errIP
					// left side
					IF (numpnts(LevelIdx)>0)
						errIN=abs(1/(273+fitparams[1])-1/(273+tempT[LevelIdx[0]]))
						errN=abs(fitparams[1]-tempT[LevelIdx[0]])	//distance to first level crossing
					ELSE
						// use distance from 0C as width
						errIN=0
						errN=0
					ENDIF
					// right side
					IF (numpnts(LevelIdx)>1)	// catch peak too close to end
						
						errIP=abs(1/(273+fitparams[1])-1/(273+tempT[LevelIdx[numpnts(LevelIdx)-1]]))
						errP=abs(fitparams[1]-tempT[LevelIdx[numpnts(LevelIdx)-1]])	//distance to second level
					ELSE
						errIP=errIN
						errP=errN	
					ENDIF
					// catch if left side out of range
					IF (errN==0)
						ErrIN=errIP
						ErrN=ErrP
					ENDIF
					
					FactorTmaxIerr[ee][ff][0]=errIP
					FactorTmaxIerr[ee][ff][1]=errIN
					
					FactorTmaxerr[ee][ff][0]=errP
					FactorTmaxerr[ee][ff][1]=errN
					
				CATCH
					DebuggerOptions debugonerror=1
					
					Variable Error=GetRTError(1)
					print "MPpost_getFactorContrib(): Error while fitting Factor Thermogram - "+getErrMessage(Error)
				ENDTRY
				
				// if no fit was performed maximum position of curve will be used
				FactorTmax[ee][ff]=fitparams[1]	// T max in C
				FactorTmaxI[ee][ff]=1/(fitparams[1]+273)	// T^-1 in K
				
			ENDIF
							
		ENDIF
		
			
		
	ENDFOR	// factor loop

ENDFOR	// experiment loop

// convert Tmax to Cstar
IF (doCstar==1 && MStype== 2)
	Wave	MWFactor=avgMWfactor	// signal weighted average MW of each factor
	
	Make/FREE/D/N=(dimsize(logCstar_split,0),dimsize(logCstar_split,1)) psat, psatErr_minus,psatErr_plus,cstarErr_plus,CstarErr_minus
	
	psat=exp(calparams[0] + FactorTmax[p][q]*calparams[1])
	logCstar_split=log(psat*MWFactor[q]/8.314/298*1e6)
	
	// Tmax +/- half width of factor fit
	psatErr_minus=exp(calparams[0] + (FactorTmax[p][q]+FactorTmaxerr[p][q][0])*calparams[1])
	psatErr_plus=exp(calparams[0] + (FactorTmax[p][q]+FactorTmaxerr[p][q][1])*calparams[1])
	
	CstarErr_minus=log(psatErr_minus[p][q]*MWFactor[q]/8.314/298*1e6)
	CstarErr_plus=log(psatErr_plus[p][q]*MWFactor[q]/8.314/298*1e6)
	
	logCstarErr_split[][][0]=abs(logCstar_split[p][q]-CstarErr_minus[p][q])
	logCstarErr_split[][][1]=abs(logCstar_split[p][q]-CstarErr_plus[p][q])

ENDIF

// normalise factor contribution
setdatafolder $resultFolderStr

duplicate/O FactorContrib_abs,FactorContrib_rel
Make/O/D/N=(numpnts(explist)) totalSig

Sumdimension/D=1/DEST=totalSig FactorContrib_abs
FactorContrib_rel[][]=FactorContrib_abs[p][q]/totalSig[p]

// clean up
Killwaves /Z fitParams,tempF_fit,constrains,LevelIdx,FareaTemp,totalSig,TempF,TempT

// plot VBS
IF (quiet==0 && MStype==2)
	FolderPath+=":"+resultfolderstr
	MPplot_plotPMFVBS(FolderPath,ExpListName,FactorContrib_rel,FactorList,FactorTmaxI,FactorTmaxIerr)
ENDIF

setdatafolder ::

END

//======================================================================================
//======================================================================================


// Purpose:		export PMF results to txt files 
//					e.g. to transfer to Matlab
//					FiT-PET Panel assumes solutions are in 'root:PMFresults'. 
//					call this function from command line to export fromany folder tree

// Input:			folderStr:		String with full path to solution that should be exported
//					Wavenames:		Wave with name of data waves (must contain dimension labels)
//					MStype:			selected MS type from panel
//					timeformat:		0: Igor sec, 1: Matlab, 2: text
//					timeformatStr: 	string for time 2 text conversion
//					includeOriginal:	1: include MSdata and MSerr in export
//					user is prompted for saving location

// Output:		txt files with F and G matrix
//					name of solution iwll be used for file name
// called by:	MPbut_step3_button_control -> but_exportSolution or stand-alone

FUNCTION MPpost_exportSolution2txt(folderStr,Wavenames,MStype,timeformat,timeformatStr,includeOrg)
			
String folderStr
Wave/T wavenames		
Variable MStype
variable timeformat
String timeformatStr
Variable includeOrg			

// get abort Str
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

String oldFolder=getdatafolder(1)

Setdatafolder root:

// check solution folder
IF(!datafolderExists(folderStr))
	abortStr="MPpost_exportSolution2txt():\r\rcannot find selected solution folder:\r" + folderStr
	MPaux_abort(abortStr)
ENDIF

IF (!Waveexists($(folderStr+":Factor_MS1")))	// folder exists but does not have the right waves
	abortStr="MPpost_exportSolution2txt():\r\rcannot find wave: \r"+folderStr+":Factor_MS1"
	abortSTr+="\rmake sure the solutions were exported with 'get solution' button from Panel"
	MPaux_abort(abortStr)
ENDIF

// prompt user for saving location
PathInfo/S PAth4Export	// preset folder 

NewPath/Q/O/M="Select a saving location for export" Path4export

// catch user canceled
IF (V_flag!=0)
	abort
ENDIF

PathInfo/S PAth4Export
String savePath=S_path

Setdatafolder $folderStr

// make names for files
String solutionName=Stringfromlist(Itemsinlist(folderStr,":")-1,folderStr,":")	// use last folder in Path

String saveMS=solutionName+"_FactorMS.txt"
String saveThermos=solutionName+"_FactorTS.txt"
String saveMZ=solutionName+"_IonMass.txt"
String saveIonLabel=solutionName+"_IonLabel.txt"
String saveIDXsample=solutionName+"_IDXsample.txt"

// name for "timeseries"/Tdesorp
String saveTdesorp=solutionName+"_tseries.txt"
Variable TestFigTime=0
IF (MStype==2)	// if Figaero thermograms
	saveTdesorp=solutionName+"_Tdesorp.txt"
	// catch if FigTime is present
	IF (!stringmatch(Wavenames[%FigTimeName],""))
		TestFigTime=1
		String saveFigTime=solutionName+"_FigTime.txt"
	ENDIF
	
ENDIF

String dataType=""
SWITCH (MStype)
	CASE 0:
		dataType="general HR gas phase data"
		BREAK
	CASE 1:
		dataType="general UMR gas phase data"
		BREAK
	CASE 2:
		dataType="FIGAERO thermogram data"
		BREAK
	CASE 3:
		dataType="FIGAERO integrated MS data"
		BREAK
	CASE 4:
		dataType="Aerosol MS HR data"
		BREAK
	CASE 5:
		dataType="Aerosol MS HR data"
		BREAK
	CASE 6:
		dataType="Aerosol MS UMR data"
		BREAK
	CASE 7:
		dataType="Aerosol MS UMR data (old ACSM)"
		BREAK
	CASE 8:
		dataType="Aerosol MS UMR data (Q-AMS)"
		BREAK

ENDSWITCH

// make list for saving
String Thermoslist=Wavelist("Factor_TS*",";","")

String MSlist=""

Variable formatCheck=0

Variable ww
FOR (ww=0;ww<Itemsinlist(ThermosList);ww+=1)
	MSlist+="Factor_MS"+num2str(ww+1)+";"
ENDFOR

// SAVE
Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W ThermosList as saveThermos
Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W MSlist as saveMS
Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%MZname] as saveMZ
Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%Labelname] as saveionlabel
Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W "idxSample" as saveIDXsample	// Sample IDX wave is always IDXsample in exported solutin folders !

SWITCH (timeformat)
	CASE 0:
		// Igor sec or no format 
		Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%Tname] as saveTdesorp
		IF (testFigTIme==1)	// FigTime
			Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%FigTimeName] as saveFigTime
		ENDIF
		
		BREAK
	CASE 1: 
		// Matlab sec
		// convert to Matlab sec
		Wave Tseries=$(Wavenames[%Tname])
		Duplicate/O Tseries, Tseries_Mat
		Tseries_Mat=MPaux_Igor2MatlabTime(Tseries)
		
		Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W Tseries_Mat as saveTdesorp
		
		IF (testFigTIme==1)	// FigTime
			Wave FigTime=$(Wavenames[%FigTimename])
			Tseries_Mat=MPaux_Igor2MatlabTime(FigTime)
			Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W Tseries_Mat as saveFigTime
		ENDIF
		
		Killwaves/Z Tseries_Mat
		BREAK
	CASE 2: 
		// Text
		Wave Tseries=$(Wavenames[%Tname])
		Make/O/T/N=(numpnts(Tseries)) Tseries_txt
		Tseries_txt=MPaux_js2String(Tseries,timeformatStr,noabort=1)
		// check if conversion worked
		IF (Stringmatch(Tseries_txt[0],"Wrong Format"))	// format could not be identified
			// unidentified format -> write original without conversion
			Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%Tname] as saveTdesorp
			formatCheck=1
		ELSE
			// conversion worked -> save text
			Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W Tseries_txt as saveTdesorp
		ENDIF
		
		IF (testFigTIme==1)	// FigTime
			Wave FigTime=$(Wavenames[%FigTimename])
			Tseries_txt=MPaux_js2String(FigTime,timeformatStr,noabort=1)
			// check if conversion worked
			IF (Stringmatch(Tseries_txt[0],"Wrong Format"))	// format could not be identified
				// unidentified format -> write original without conversion
				Save/P=Path4Export/J/B/DLIM="\t"/DSYM="." /M="\r\n"/W Wavenames[%FigTimeName] as saveFigTime
				formatCheck=1
			ELSE
				// conversion worked -> save text
				Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W Tseries_txt as saveFigTime
			ENDIF


		ENDIF
		
		Killwaves/Z Tseries_txt
		BREAK
ENDSWITCH

// notify user about saving
Print "-----------------------"
print date()+" "+time()+" Exporting PMF solution"
print "Type: "+dataType
print "source folder: "+folderStr
print "saving location: "
print SavePath+saveThermos
print SavePAth+saveMS
print SavePath+saveMZ
print SavePAth+saveIonLabel
print SavePath+saveTdesorp

IF (formatCheck==1)
	print "User requested saving time data as text with format:\r  "+ timeformatStr
	print "Unable to identify format -> saved data without conversion instead. Choose one of the supported formats, e.g.:"
	print "dd.mm.yyyy hh:mm:ss\r  hh:mm:ss dd.mm.yyyy\r  yyyy-mm-dd hh:mm:ss"
ENDIF
IF (testFigTIme==1)
	print SavePath+saveFigTime
ENDIF
print SavePath+saveIDXsample

// include MSdata and MSerr
IF (includeOrg==1)
	
	print "User selected to export original data matrix."

	String saveMSdata=solutionName+"_MSdata.txt"
	String saveMSerr=solutionName+"_MSerror.txt"
	
	// get waves from waves4PMF
	String WaveNote=Note(Wavenames)
	String folderPath=Stringfromlist(1,Wavenote,"\r")
	
	IF (!DatafolderExists(folderPath))	// check if folder exists
		
		abortStr="MPpost_exportSolution2txt:\r\ruser selected to export original data, but source folder could not be determined from WaveNote of wave "
		abortStr+=getwavesDatafolder(Wavenames,2)
		abortStr+="\r\rcheck Hitory for WaveNote text"
		
		print "original data folder could not be determined."
		print "Wavenote text of wave "+getwavesDatafolder(Wavenames,2)
		print WaveNote
		
		Setdatafolder $oldFolder
		
		MPaux_abort(abortStr)

	ENDIF
	
	FolderPath=removeending(folderpath,":")

	Variable test=0
	
	// save MSdata
	Wave/Z MSdata=$(folderPath+":"+Wavenames[%MSdataName])
	IF (Waveexists(MSdata))
		Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W MSdata as saveMSdata
		print "MSdata as:	" + Savepath+saveMSdata
	ELSE
		// no wave found
		print "No MSdata wave found with name:"
		print getwavesDatafolder(MSdata,2)
	ENDIF

	// Save MSerror
	Wave/Z MSerr=$(folderPath+":"+Wavenames[%MSerrName])
	IF (Waveexists(MSdata))
		Save/P=Path4Export/J/DLIM="\t"/DSYM="." /M="\r\n"/W MSerr as saveMSerr
		print "MSerror as:	" + Savepath+saveMSerr
	ELSE
				// no wave found
		print "No MSerror wave found with name:"
		print getwavesDatafolder(MSerr,2)
	ENDIF
	
ENDIF


Setdatafolder $oldFolder

END


//======================================================================================
//======================================================================================

// Purpose:	calculate the average thermogram over multiple samples from PMFresults output from MaS-PET
//				T grid can be adjusted (5C was good value so far)
//				
//				for each sample, factors are only included if they have at least 'MinValue' contribution
//				
// Input:		folderStr: 	name of data folder to work on (e.g. "root:PMFresults:Combi_F5_0")
//				MinValue:	factors must have at least this contribution in a sample (typical 0.01) to be used for the averaging
//				gridWidth:	width of Tdesorp grid (i.e. Tdesorp is binned in a grid with 20+i*gridwidth). 5 works well in most cases
//				doPlot:		0/1 to turn on plotting of results
//
// Output:	wave are in new subfolder ":avgFactorThermo"
//				average factor thermogram for each factor in given solution
//				plot with averaged factor thermogram values


FUNCTION MPpost_CalcAvgFactorThermo(folderStr,MinValue,gridWidth,doPlot,TdesorpName,ExplistName)

String folderStr
Variable MinValue
Variable GridWidth
Variable DoPlot
String TdesorpName
String ExplistName

Setdatafolder root:

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// -----------------------------------------------------------------

// basic checks
// check if data folder exists
IF (!datafolderexists(folderStr))	// check if data folder exists
	
	abortSTr="MPpost_CalcAvgFactorThermo():\r\rfolder not found:\r"+folderStr
	MPaux_abort(abortStr)
	
ENDIF

Setdatafolder $folderStr

// check if factor MS and time series waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderStr)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_CalcAvgFactorThermo():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() +" "+time()+"\tcalculating average thermograms:"
	print "Check Wavenames in folder: "+folderStr
	print "expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_CalcAvgFactorThermo():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderStr
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

// check for wave with index values of samples
Wave tdesorp=$TdesorpName	// Wave with Tdesorp values
IF (!Waveexists(Tdesorp))	// check if wave exists
	abortStr="MPpost_CalcAvgFactorThermo():\r\rno wave with Tdesorp/time data found in folder: \r"+folderStr
	MPaux_abort(abortStr)
ENDIF

// check for wave with index values of samples
Wave ExpList=$ExpListName	// Wave with Tdesorp values
IF (!Waveexists(ExpList))	// check if wave exists
	abortStr="MPpost_CalcAvgFactorThermo():\r\rno wave with ExpList found in folder: \r"+folderStr
	MPaux_abort(abortStr)
ENDIF

// check for idxSample wave and make new one
MPaux_check4IDXSample("IdxSample",FolderStr,Tdesorp,Explist)
Wave/D idx_Sample=$(FolderStr+":IdxSample")

// get sample and factor number

Variable nos=dimsize(IDX_sample,0)	// number of samples

Wave anote
Variable nof=anote[0]	// number of factors

// -----------------------------------------------------------------

// set up containers for results and intermediate stuff

Duplicate/FREE tdesorp,tdesorp_sorted

Make/D/O/N=(numpnts(tdesorp),nof) Factor_TS_scaled=0,Flag_tseries=1
Make/D/O/N=(dimsize(idx_sample,0),nof) Flag_timeStamp=1

Newdatafolder/O/S avgFactorThermo

// temperature grid setup
Variable maxT=250	// max value for T grid
Variable minT=20		// start value for T grid
Variable CheckValue=180	// check if Tdesorp values were shifted with ii*200, default 180

Variable not=round((maxT-minT)/gridwidth)	// number of temeprature points in grid (from 20C - 200C, grid point are gridWidth apart

Make/D/O/N=(not) Tdesorp_avg=(minT+(p*gridwidth)+gridwidth/2)	// shift to middle of grid cell
Note Tdesorp_avg,"middle of T grid cell;width:"+num2str(gridwidth)

Variable ff,jj,tt

Wave/Z CurrentContrib=$("::FactorContrib_Tmax:FactorContrib_rel")	
IF (!Waveexists(CurrentContrib))
	abortStr="MPpost_CalcAvgFactorThermo():\r\rcannot find Factor contribution data. Use FiTPET functions to generate this output"
	MPaux_abort(abortStr)
ENDIF

// loop through factors
Variable test=0
FOR(ff=0;ff<nof;ff+=1) // factor loop

	Wave CurrentFactor=$("::Factor_TS"+num2Str(ff+1))	// current factor thermogram
	
	// loop through samples
	FOR (jj=0;jj<(nos);jj+=1)	// samples loop
	
		// create scaled thermograms (scale to peak height)
	
		Make/FREE/D/N=(idx_sample[jj][1]-idx_sample[jj][0]+1) Thermo1=0
		Thermo1=CurrentFactor[p+idx_sample[jj][0]]
		
		Variable Maximum=WaveMax(Thermo1)
		
		Factor_TS_scaled[idx_sample[jj][0],idx_sample[jj][1]][ff]=thermo1[p-idx_sample[jj][0]]/Maximum
		
		// identify weak contributions
		IF (CurrentContrib[jj][ff]<MinValue)
			Flag_tseries[idx_sample[jj][0],idx_sample[jj][1]][ff]=0
			Flag_timeStamp[jj][ff]=0
		ENDIF
		
		// store Tdesorp data (including check for Tdesorp = T+ 200*ff)
		IF (ff==0)
			IF (tdesorp[idx_sample[jj][0]] > checkValue )	// first entry for sample >180C?
				tdesorp_sorted[idx_sample[jj][0],idx_sample[jj][1]]=tdesorp[p]-jj*200
			ELSE
				tdesorp_sorted[idx_sample[jj][0],idx_sample[jj][1]]=tdesorp[p]
			ENDIF
		ENDIF
		
	ENDFOR // samples loop
	
	// sort all thermograms of 1 factor by Tdesorp
	make/Free/D/N=(numpnts(CurrentFactor)) SortedThermo=Factor_TS_scaled[p][ff]
	
	SortedThermo = Flag_tseries[p][ff]<MinValue ? NaN : SOrtedThermo[p]// remove weak contributions
	
	// sort by Tdesorp values
	Sort tdesorp,Tdesorp_sorted
	Sort Tdesorp,sortedThermo
	
	// output container for each Factor
	Make/O/D/N=(numpnts(Tdesorp_avg),2) $("AVGthermo_F"+num2Str(ff+1))
	Wave CurrentTHermoDiel=$("AVGthermo_F"+num2Str(ff+1))
	Note CurrentTHermoDiel,"rows: samples\r columns: mean;stdev"
	
	// loop through temperature bins
	FOR (tt=0;tt<not;tt+=1)
		
		Extract/FREE SortedThermo,ThermoSlice,tdesorp_sorted >= minT+(tt*gridwidth) && tdesorp_sorted < minT+(tt+1)*gridwidth
		Extract/FREE Tdesorp_sorted,TdesorpSlice,tdesorp_sorted >= minT+(tt*gridwidth)*gridwidth && tdesorp_sorted < minT+(tt+1)*gridwidth
		
		IF (numpnts(ThermoSlice)>0)	// catch empty Thermoslice wave (= no points in grid cell)
			Wavestats/Q ThermoSlice
		
			CurrentTHermoDiel[tt][0]=V_avg
			CurrentTHermoDiel[tt][1]=V_sdev
			
			test+=1
		ELSE
			CurrentTHermoDiel[tt][0]=nan
			CurrentTHermoDiel[tt][1]=nan
		ENDIF
		
	ENDFOR //Temperature bin loop
	
	Wave CurrentFactor=$("")
ENDFOR // factor loop

// make plot
IF (doPlot==1)
	
	MPplot_plotAvgDiel(folderStr,4,0)

ENDIF

// feedback to user
// if no data point were found for any factor/gridpoint -> most likely wrong format for Tdesorp
If (test==0)
	
	print "-------------------------------"
	print date() +" "+time()+"\tcalculating average thermograms:"
	print "no data points found for any of the default grid point between "+num2str(minT)+" and "+num2str(maxT)+" C"
	print "check if input data is really desorption temperature:"
	print "Tdesorp wave: "+folderStr+":"+TdesorpName
ENDIF

END


//===============================================
//===============================================
// Purpose:	calculate the diurnal patterns of factor contribution from PMFresults output from MASPET
//				Each factor is scaled with the sum of the factor
//				
// Input:		folderStr: 		name of data folder to work on (e.g. "root:PMFresults:Combi_F5_0")
//				TimeStampName:	Name of Wave with Time stamps for the samples (in Igor time)
//				hourGrid:			width of hour grid (i.e. 0+i*hourGrid) 2 means grouping into 2h bins starting from Midnight	
//				MinValue:			factors must have at least this contribution in a sample (typical 0.01) to be used for the averaging
//				doPlot:			0/1 to turn on plotting of results
//
// Output:	wave are in new subfolder ":FactorDiel"
//				diurnal patterns for each factor in given solution
//				plot with diurnal patterns of factor contribution values
//				sideeffect: VBS_ALL will be converted to new folder name


FUNCTION MPpost_CalcFactorDiurnals(folderStr,TimeStampName,hourGrid,MinValue, doPlot)

String folderStr
String TimeStampName
Variable hourGrid
Variable MinValue
Variable DoPlot

Setdatafolder root:

// catch if called from APP
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

String alertStr=""

// basic checks
// check if data folder exists
IF (!datafolderexists(folderStr))	
	abortSTr="MPpost_CalcfactorDiurnals():\r\rfolder not found:\r"+folderStr
	MPaux_abort(abortStr)
ENDIF

Setdatafolder $folderStr

// check if factor MS and time series waves exist
Variable WaveCheck=MPaux_check4FitPET_MSTS(folderStr)
// old FiT-PET export found -> user aborted
IF (WaveCheck==0)
	abortStr="MPpost_CalcAvgFactorThermo():\r\rOnly old FiT-PET type waves found in solution data folder -> User aborted."
	abort
ENDIF
// no waves found with MaS-PET or FiT-PET names
IF (Wavecheck==-1)
	// print more details into History window
	print "------------------"
	print date() +" "+time()+"\tcalculating scaled diurnal trends:"
	print "Check Wavenames in folder: "+folderStr
	print "Expected Wavenames for "
	print "\t\tfactor Mass spectra:\t'Factor_MS1' or 'FactorMS1_rel'"
	print "\t\tfactor time series:\t'Factor_TS1' or 'FactorThermo1'"
	
	// abort
	abortSTr="MPpost_CalcAvgFactorThermo():\r\rNo PMF solution waves found in folder:\r"
	abortSTr+=folderStr
	abortStr+="\r\rcheck History Window for the required Wave names"
	
	MPaux_abort(abortStr)
	
ENDIF

// check if "FactorContribution" exists -> change VBS into it
IF (!datafolderexists("FactorContrib_Tmax"))
	
	IF(datafolderexists("VBS_all"))	// VBS_all folder was found?
		alertStr="The folder 'VBS_all' was changed to 'FactorContrib_Tmax' in FitPET 1.8. Do you want to convert the existing VBS_all folder (YES) or abort(NO)?"
		DoAlert 1, alertStr
		
		IF (V_FLAG==1)	// yes
			MPpost_convertVBS_allFolder(folderStr,"VBS_all")
		ELSE	// NO
			abortStr="MPpost_CalcfactorDiurnals():\r\rno folder with name 'FactorContrib_Tmax' found in folder:\r"+folderStr
			abortStr+="\ruser chose abort"
			abort
		ENDIF
	
	ELSE
		// no VBS_all folder
		abortStr="MPpost_CalcfactorDiurnals():\r\rno folder with name 'FactorContrib_Tmax' or 'VBS_all' found in folder:\r"+folderStr
		abortStr+="\ruse 'get solution' in FiTPET or 'getVBS_APP()' to calculate this data"
		MPaux_abort(abortStr)
	ENDIF
	
ENDIF

// Wave with factor contributions for each sample
// think about using rel contribution or abs contributions $$$
Wave/Z allFactors=:FactorContrib_Tmax:FactorContrib_abs	// this is the factor contribution, using ALL factors

IF (!WaveExists(allFactors))
	abortStr="MPpost_CalcfactorDiurnals():\r\rWave 'FactorContrib_abs' not found in folder: \r"+folderStr+":FactorContrib_Tmax"
	abortStr+="\r\ruse 'get solution' in MaS-PET or 'getVBS_APP()' to calculate this data"
	MPaux_abort(abortStr)
ENDIF

// check for time stamp wave has happened before
Wave timeStamp=$(":FactorContrib_Tmax:"+TimeStampName)
IF (!Waveexists(timeStamp))
	abortstr="MPpost_CalcfactorDiurnals():\r\rNo timestamp wave found with this name:\r"+folderStr+":FactorContrib_Tmax:"+TimeStampName
	MPaux_abort(abortStr)
ENDIF

//---------------------------------

Newdatafolder/O/S :FactorDiel

// make time grid
Variable not=ceil(24/hourGrid)	// 24 h / gridwith -> number of bins

Make/D/O/N=(not) Time_diur=p*hourGrid
Note Time_diur, "Midpoint of hour grid in h; width:"+num2str(hourGrid)

// convert time stamp to only hour of day and only day
Make/FREE/T/N=(numpnts(timeStamp)) hourOfDay_txt,date_txt
Make/O/D/N=(numpnts(timeStamp)) hourOfDay,date_stamp

hourOfDay_txt=MPaux_js2string(timeStamp,"hh:mm:ss")
hourOfDay=str2num(stringfromlist(0,hourOfDay_txt,":"))

date_txt=MPaux_js2string(timeStamp,"dd.mm.yyyy")
date_stamp=MPaux_string2js(date_txt,"dd.mm.yyyy")

findduplicates /RN=days date_stamp

// scale each day

duplicate/O allFactors, ::FactorContrib_TMAx:FactorContrib_dayscaled
Wave allfactors_scaled=::FactorContrib_TMAx:FactorContrib_dayscaled

Variable ii,jj,dd,tt

// scale each factor of each day with sum of that day
FOR (dd=0;dd<numpnts(days);dd+=1)	// day loop
	// get 1 day data
	Extract/FREE/INDX date_stamp, IDX, date_stamp == days[dd]
	
	IF (numpnts(IDX)>0)
	
		// scale to sum of that day
		Variable idxStart,idxEnd
		idxStart=IDX[0]
		idxend=idx[numpnts(idx)-1]
	
		duplicate/O/R=[idxStart,idxEnd][0,*] allFactors, currentSlice
		Wave CUrrentSlice
		
		Wavestats/PCST/Q/Z/M=1/P currentSLice	// get sum of each factor signal in that day
		Wave M_Wavestats
		
		CurrentSlice/=M_Wavestats[23][q]	//3= average 23= sum
		allfactors_scaled[idxStart,idxEnd][]=currentSlice[p-idxStart][q]
		
	ENDIF
	
ENDFOR	// day loop

// loop through factors
	Variable testLT3=0
	Variable testNP=0
	String hourStrLT3=""
	String hourStrNP=""

FOR(ii=0;ii<dimsize(allFactors,1);ii+=1) // factor loop
	
	hourStrLT3+="\r\tF"+num2str(ii+1)+":\t"
	hourStrNP+="\r\tF"+num2str(ii+1)+":\t"
	
	// get one factor
	Make/FREE/D/N=(dimsize(allFactors,0)) CurrentContrib
	CurrentContrib=allfactors_scaled[p][ii]
	
	// result wave
	Make/O/D/N=(numpnts(Time_diur),5) $("FactorDiel_F"+num2Str(ii+1))
	Wave CurrentFactorDiel=$("FactorDiel_F"+num2Str(ii+1))
	Note CurrentFactorDiel,"Median Value;25th Percentile;75th percentile;Median-25th;75th-Median;"
	
	// container for violin/box plot
	Variable WaveLength=max(12,numpnts(timeStamp)/(0.1*not))	// have at least 12 rows
	
	Make/D/O/N=(Wavelength,not) $("FactorSorted_F"+num2Str(ii+1))
	Wave CurrentFactorSorted=$("FactorSorted_F"+num2Str(ii+1))
	CurrentFactorSorted=NaN
	
	// clean data to use only times when factors are active
	duplicate/FREE CurrentContrib, CurrentContrib_clean, test

	// loop through hours of the day
	FOR (tt=0;tt<not;tt+=1)	// hours of day loop

		// start and end value of grid
		Variable startTime=Time_diur[tt]
		Variable EndTime=Time_diur[tt]+hourGrid	// does not matter if > 24
		
		// extract data points		
		Extract/FREE CurrentContrib_clean,ContribSlice,hourOfDay>=startTime && hourOfDay<endTime && CurrentContrib_clean>minvalue

		IF (numpnts(ContribSlice)>0)
			
			// for 3 points or more (StatsQuantiles needs 3 points)
			IF (numpnts(ContribSlice)>2)
				StatsQuantiles/Z/Q/iNAN ContribSlice
			
				CurrentFactorDiel[tt][0]=V_median
				CurrentFactorDiel[tt][1]=V_Q25
				CurrentFactorDiel[tt][2]=V_Q75
				CurrentFactorDiel[tt][3]=V_median-V_Q25		
				CurrentFactorDiel[tt][4]=V_Q75-V_median
				
			ELSE
				// for less points -> use mean and stdev
				testLT3=1
				hourStrLT3+="\t"+num2str(Time_diur[tt])+";"
				Wavestats/Q ContribSlice
				
				CurrentFactorDiel[tt][0]=V_avg
				IF (numtype(V_sdev)!=0)	// catch if only 1 point and sdev is NaN
					V_sdev=0				
				ENDIF
				CurrentFactorDiel[tt][1]=V_avg-V_sdev
				CurrentFactorDiel[tt][2]=V_avg+V_sdev
				CurrentFactorDiel[tt][3]=V_sdev		
				CurrentFactorDiel[tt][4]=V_sdev			
			ENDIF
			
			CurrentFactorSorted[0,numpnts(ContribSlice)-1][tt]=ContribSlice[p]
		ELSE
			// if nothing found -> put 0
			CurrentFactorDiel[tt][0]=0
			CurrentFactorDiel[tt][1]=0
			CurrentFactorDiel[tt][2]=0
			CurrentFactorDiel[tt][3]=0
			CurrentFactorDiel[tt][4]=0
			
			CurrentFactorSorted[0][tt]=0
			
			testNP=1
			hourStrNP+="\t"+num2str(Time_diur[tt])+";"			
		ENDIF	
			
	ENDFOR // hours of day loop
	
	Wave CurrentFactor=$("")
ENDFOR	// factor loop

Time_diur+=hourgrid/2	// shift by half of grid width

// clean up
Killwaves/Z currentSlice, days, date_stamps, hourOfDay, W_statsQuantiles, M_Wavestats

// make plot
IF (doPlot==1)
	
	MPplot_plotAvgDiel(folderStr,4,1)

ENDIF

// print info about too few points
IF((testLT3+testNP)>0)
	print "------------------------------"
	print date() +" "+time()+"\tcalculating scaled diurnal trends:"
	IF(testLT3>0)
		print "Some grid point in the scaled diurnal calculations had only 1 or 2 data points. Values are mean +/- stdev instead of median"
		print "affected hours:"+ hourStrLT3
	ENDIF
	IF(testNP)
		print "Some grid points in the scaled diurnal calcualations had no data points."
		print "affected hours:"+hourStrNP
	ENDIF
ENDIF

END


//=======================================
//=======================================

// Purpose:	Convert the VBS_all folder and its content to the new format of FactorContribution
//				VBS_all is created in FITPET <v1.8, FactorContirbution will be created with v1.8 and higher
//				The content is the same BUT the orientation of the waves is flippped:
//				each column is a factor, each row is a sample
// Input:		folderStr: 	name of data folder to work on (e.g. "root:PMFresults:Combi_F5_0")
//				VBSname:		name of data folder to convert
// Output:	new subfolder ":FactorContrib_Tmax" with data from old VBS_all folder turned to "normal" column/row system
//				

FUNCTION MPpost_convertVBS_allFolder(folderStr,VBSname)

String folderStr
String VBSname

String oldFolder=getdatafolder(1)

Setdatafolder $FolderStr

// get abortStr
SVAR/Z abortStr=root:App:abortStr

IF (!SVAR_exists(abortStr))
	String/G abortStr=""
ENDIF

// check if VBS folder exists
IF (!datafolderexists(VBSname))
	abortStr="MPpost_convertVBS_allFolder():\r\rno folder with name:\r"+VBSname+"\rfound in folder\r"+folderStr
	MPaux_abort(abortStr)
ENDIF

Newdatafolder/O :FactorContrib_Tmax

String oldWaveNames="TmaxErr_split;TmaxIErr_split;Tmax_split;TmaxI_split;VBSrel_split;VBS_split;"
String newWaveNames="FactorTmaxErr;FactorTmaxIErr;FactorTmax;FactorTmaxI;FactorContrib_rel;FactorContrib_abs;"

Variable ii=0

// loop through waves
FOR(ii=0;ii<Itemsinlist(oldWaveNames);ii+=1)
	
	Wave CurrentOldWave=$(":"+VBSname+":"+Stringfromlist(ii,oldWaveNames))
	
	Wave/Z CurrentNewWave=$""
	
	Duplicate/O CurrentOldWave, $(":FactorContrib_Tmax:"+Stringfromlist(ii,newWaveNames))
	wave CurrentNewWave=$(":FactorContrib_Tmax:"+Stringfromlist(ii,newWaveNames))
	
	IF (wavedims(CurrentNewWave)==2)
		// 2D waves
		Matrixtranspose CurrentNewWave
	ELSE
		// 3D waves
		Duplicate/FREE CurrentNewWave,dummy
		MatrixOP/S/O CurrentNewWave=transposeVol(dummy,5)	// MatrixOP can't overwrite selve
	ENDIF
	
ENDFOR

// reset datafolder
Setdatafolder $oldFolder

END

//=======================================
//=======================================
