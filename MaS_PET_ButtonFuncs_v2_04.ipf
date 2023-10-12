#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



//======================================================================================
//	MaS_PET_ButtonFuncs is a collection of functions executing actions for buttons in the MaS-PET Panel. 
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


//===================================
//===================================
//			MaS-PET button functions
//===================================
//===================================

// Purpose:	collection of button functions for MaSPET and connected panels (push buttons, checkboxes, radio buttons, ad help buttons
//				the functions only work in the context of MaSPET!
//				
// Input:		ctrlStruct: structure with detailed information of the button/control which called the procedure
//
// Output:	strongly depends on function
//
//======================================================================================
//		push buttons
//======================================================================================

//======================================================================================
//======================================================================================
// master function for buttons
// uses Ctrlname to select which function is called

// buttons in step 0 and step 1

FUNCTION MPbut_step1_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct


// get globals and waves
SVAR abortStr=root:APP:abortStr				// string with abort info
SVAR ExpList_Str=root:APP:ExpList_Str		// name of wave with expfolders
SVAR removeIons_wave_Str=root:APP:removeIons_wave_Str	//name of wave with 0/1 for remove ions
SVAR Combiname_Str=root:APP:combiname_Str	// name of combi datafolder (target for makeCombi()
SVAR SGerrorFolderName=root:APP:SGerrorFolderName	// name of folder with SG error data for PL error parameter fit
						
Wave/Z cbValues_prepData=root:app:cbvalues_prepData				// check box values
Wave/Z radioValues_removeIons=root:app:radioValues_removeIons	//radio button settings

Wave/Z/T ExpList=$ExpList_Str								// Explist wave
Wave/T/Z OriginalNames=root:App:OriginalWaveNames	// wave with names of original waves -> not used anymore
Wave/T/Z WaveNames=root:App:DataWavenames				// wave with names of PMF waves
Wave/Z Removeions_IDX=$removeIons_wave_Str				// wave with removeIon IDX

NVAR removeions_IDX_Var=root:app:removeions_IDX_Var			// ion idx for current ion in removeIons action
SVAR removeions_IDX_label=root:app:removeIons_label_Str		// ion label for current ion in removeIons action

// local varianbles			
Variable ionIDX=-1
Variable ii

variable oldResolution

// set right data folder
String oldfolder=getdatafolder(1)
setdatafolder root:

// only execute when releasing mouse button
IF(ctrlStruct.eventCode==2)	
	
	String folderPath=""
	String alertStr=""
	
	// check for Wavenames Wave
	IF (!Waveexists(Wavenames))
		abortSTr="MPbut_step1_button_control():\r\rSomething is very wrong: Wavenames wave does not exists. Recreate FIT-PET panel to fix this."
		MPaux_abort(AbortStr)
	ENDIF
	
	// check for colons at end of folder names
	Combiname_Str=removeending(Combiname_Str,":")
	SGerrorFolderName=removeending(SGerrorFolderName,":")
										
	// check which button was pressed
	
	STRSWITCH(ctrlStruct.ctrlName)	// string switch
		
		// help buttons
		
		// opn online doc with FITPET manual
		CASE "but_manual":
			BrowseURL "https://docs.google.com/document/d/1Pp3fKmbjSWsZof1nTggsZeYA08lPByCMNrzk0OhDxBw/edit?usp=sharing"
			BREAK	
		// open PMF wiki
		CASE "but_Wiki": 
			BrowseURL "http://cires.colorado.edu/jimenez-group/wiki/index.php/PMF-AMS_Analysis_Guide"
			BREAK
		// open BUchholz FIGAERO thermogram PMF paper
		CASE "but_BuchholzPaper": 
			BrowseURL "https://acp.copernicus.org/articles/20/7693/2020/acp-20-7693-2020.pdf"
			BREAK
		// open Ulbrich PMF paper
		CASE "but_UlbrichPaper": 
			BrowseURL "http://www.atmos-chem-phys.net/9/2891/2009/acp-9-2891-2009.pdf"
			BREAK
		
		//----------------------------------

		// show table with ExpList wave
		CASE "but_ShowExpListWave":
			// check if Wave exists
			IF (!Waveexists(ExpList))
				// create new wave and show
				Make/T/O/N=0 $expList_Str
				MPaux_ShowWavesAsTable(expList_Str,"ExpList_Display")
			ENDIF
			
			MPaux_ShowWavesAsTable(expList_Str,"ExpList_Display")
			BREAK
		//----------------------------------
		// get wavenames from existing waves4PMF wave
		CASE "but_getwavenames":
			
			// check for maves4PMF wave:
			IF (Waveexists($(Combiname_Str+":Waves4PMF")))
				Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
				
				// loop through entries in Wavenames wave
				FOR (ii=0;ii<numpnts(Wavenames);ii+=1)
					String LabelDummy=GetdimLabel(Wavenames,0,ii)
					Variable LabelIDX=Finddimlabel(waves4PMF,0,labeldummy)
					IF (LabelIDX>-1)	// if label is found
						WaveNames[ii]=Waves4PMF[LabelIDX]
					ELSE
						Wavenames[ii]=""					
					ENDIF
				ENDFOR
				
			ELSE
				// catch if no waves4PMF is present -> do nothing
				abortSTr="MPbut_step1_button_control - Get Names button:\r\rNo wave 'waves4PMF' found in folder:\r"
				abortStr+=Combiname_Str
				MPaux_abort(abortStr)
				
			ENDIF
			
			BREAK		
						
		//----------------------------------
		// call compareThermoPlot
		CASE "but_compareThermoPlot":
			
			// start comparison windows
			MPaux_CTP_compThermoPlot_main(WaveNames[%MSdataName],WaveNames[%MZname],WaveNames[%LabelName],WaveNames[%TName],wavenames[%MSerrName])
			
			BREAK
			
		//----------------------------------
		// call compareThermoPlot
		CASE "but_loadData":
			
			// bring to front
			doWindow/F DataLoader_panel
			
			// OR create data loader panel
			IF (!V_flag)
			
				MPprep_DL_DataLoader_Panel()

			ENDIF		
			BREAK
			
		//----------------------------------
		// call compareThermoPlot
		CASE "but_splitLoadedDAta":
			
			// prompt user for names of waves with idx and expNames 
			String folderNamesPrompt=ExpList_Str
			String idxWavePrompt="root:APP:IDXsample"
			String CombiFOlderPrompt=combiName_str
			
			String helpStr="1) Give the name of the folder with loaded data. Wavenames in FiTPET panel are used"
			helpStr+="\r2) full path to text wave containing folder names for Sample folders"
			helpStr+="\r3) full path to 2 column numeric wave with start and stop row index of the samples"
			
			Prompt CombiFolderPrompt,"Folder with loaded data"
			Prompt folderNamesPrompt, "Sample folder names (Text Wave)"
			Prompt idxWavePrompt,"Start and end row of each sample (numeric Wave,2 columns)"
			
			DoPrompt/help=helpStr "Select Data location",CombiFOlderPrompt, folderNamesPrompt,idxWavePrompt
			
			IF (V_flag==1)	// user canceled
				abort
			ENDIF
			
			// get waves with info			
			Wave /Z/T folderNames=$folderNamesPrompt
			Wave /Z idxWave=$idxWavePrompt
			
			IF(!waveexists(idxWave))	// sample index
				abortStr="MPaux_splitCombiData():\r\rcannot find wave with Sample Idx: \r\r"+ idxWavePrompt
				MPaux_abort(AbortStr)
			ENDIF
			
			IF(!waveexists(folderNames))	// sample index
				abortStr="MPaux_splitCombiData():\r\rcannot find wave with names for split folders: \r\r"+ folderNamesPrompt
				MPaux_abort(AbortStr)
			ENDIF

			// split data set
			MPaux_splitCombiData(CombiFolderPrompt,folderNames,idxWave,Wavenames)
			
			BREAK
			
		//----------------------------------	
		// call up PLerror Panel (only works if mserr was calculated at least once)
		CASE "but_PLerrPanel":
			// check for MSerr wave name
			MPaux_CheckMSerrName(Wavenames)
			
			// check if there is SG err data
			IF (!Waveexists($(SGerrorFolderName+":Sij_SG_all")))
			
				abortStr="MPbut_step1_button_control() - PLerr panel button:\r\rno SG error data found in folder:\r\r"+SGerrorFolderName
				abortStr+="\r\rcalculate error matrix (YES) or abort(NO)?"
				Doalert 1,abortStr
				
				IF(V_flag==2)	//canceled
					Setdatafolder $oldFolder
					
					abort				
				ENDIF
				
				// run error matrix calculation
				IF (!Waveexists(ExpList))
					Setdatafolder $oldFolder
					
					abortStr="MPbut_step1_button_control - PLerr Panel button:\r\rWhen trying to calculate data needed for PL error calcualtions this wave was missing wave:\r\r"+ExpList_Str
					MPaux_abort(AbortStr)
				ENDIF

				MPprep_DoSGerr(expList,WaveNames,cbValues_prepData[0])
			ELSE
				// check if waves exist
				IF (!Waveexists(ExpList))
					Setdatafolder $oldFolder
					
					abortStr="MPbut_step1_button_control() - PLerr Panel button:\r\rmissing wave:\r\r"+ExpList_Str
					abortStr+="\r\rcannot execute MPprep_CalcPLErr_Panel() without this wave"
					MPaux_abort(AbortStr)
				ENDIF
				
				// call PLerror Panel
				MPprep_PLE_PLErr_Panel_main(SGerrorFolderName,Wavenames)
			ENDIF
			
			BREAK
			
		//----------------------------------	
		// prepare data (calc error, MSint, calc elements from label, remove I from MZ)
		// this operates on single sample folders!
		
		CASE "but_prepData":
			//Variables with checkbox values
			Variable doElementFromLabel=1	 //--> always do this
			Variable doError=cbValues_prepData[1]
			Variable doremoveI=cbValues_prepData[2]
			Variable saveHisto=cbValues_prepData[0]
			
			// check if Wave exists
			IF (!Waveexists(ExpList))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - prep data button:\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcannot execute prepFIG4PMF() without this wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			// check if all folders in ExpList wave exist
			IF (MPaux_CheckExpListFolders(ExpList_Str)!=1)
				Wave NonExistIdx
				Setdatafolder $oldFolder
						
				abortStr="MPbut_step1_button_control - prep data button:\r\runable to find at least one folder selected in ExpList Wave:\r\r"
				FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
					abortStr+=Explist[NonExistIdx[ii]]+"\r"
				ENDFOR
				abortStr+="compare entries in ExpList wave with names in data browser for typos"
				MPaux_abort(AbortStr)
			ENDIF
			
			// check for MSerr wave name
			// MPaux_CheckMSerrName(Wavenames)
			
			MPprep_prepFIG4PMF(explist,WaveNames,doElementFromLabel,DoError,doremoveI,saveHisto)
			
			BREAK
			
		//----------------------------------
		// show table with removeIDX wave, ionlabel and ion MZ
		// if wave does not exist, user is prompted to stop or create the wave
		
		CASE "but_showRemoveIDXWave":
			//check waves
			IF (!Waveexists(ExpList))
				
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - show remove Ions IDX wave button:\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcheck name of Explist wave"
				
				MPaux_abort(AbortStr)				
			ENDIF
			
			// check if new wave needs to be made
			folderPath="root:"+ExpList[0]+":"
			folderPath=replaceString("root:root",folderPath,"root")
	
			IF (!Waveexists($removeIons_wave_Str))
				alertStr="MPbut_step1_button_control - show remove Ions IDX wave button:\r\rGiven remove ion wave does not exist. Create a new one with name:"
				alertStr+="\r"+removeIons_wave_Str
			
				DoALert 1,alertStr	// ask user what to do
				
				IF (V_flag==2)	// user canceled
					Setdatafolder $oldFolder
					
					abortStr=alertStr
					abort
				ENDIF
				
				// make new wave		
				Wave/Z/T ionLabel=$(folderPath+WaveNames[%LabelName])// wave with ion labels for first Explist entry
			
				IF (Waveexists(ionLabel))	// check for ion label wave
					Make/O/D/N=(numpnts(ionLabel)) $removeIons_wave_Str
					Wave removeIons_IDX=$removeIons_wave_Str
					removeions_IDX=0
				ELSE
					// wave is missing
					Setdatafolder $oldFolder
							
					abortStr="MPbut_step1_button_control - show removeIons_IDX Button:\r\rUnable to create new remove IDX wave. Wave with ion labels not found:\r\r"+folderPath+WaveNames[%LabelName]
					MPaux_abort(AbortStr)
	
				ENDIF
				
			ENDIF
			
			// create wavelist			
			String ListofWaves=folderPath+WaveNames[%MZName]+";"	// ExactMZ
			ListOfWaves+=folderPath+WaveNames[%LabelName]+";"		// IonLabel
			ListOfwaves+=removeIons_wave_Str+";"	
			
			// make table
			MPaux_ShowWavesAsTable(ListOfWaves,"RemoveIons_Table")

			BREAK
			
		//----------------------------------
		// reset current reomveions IDX wave ot 0
		CASE "but_resetIonIDX":
		
			// check if ion label wave exists
			folderPath="root:"+ExpList[0]+":"
			folderPath=replaceString("root:root",folderPath,"root")
			Wave/Z/T ionLabel=$(folderPath+WaveNames[%LabelName])// wave with ion labels for first Explist entry
			
			IF (Waveexists(ionLabel))
				// overwrite wave with new one		
				Make/O/D/N=(numpnts(ionLabel)) $removeIons_wave_Str
				Wave removeIons_IDX=$removeIons_wave_Str
				removeions_IDX=0
			ELSE
				Setdatafolder $oldFolder
						
				abortStr="MPbut_step1_button_control - reset removeIons_IDX Button:\r\rWave with MZ values not found:\r\r"+folderPath+WaveNames[%LabelName]
				MPaux_abort(AbortStr)

			ENDIF
			
			BREAK
	
		//----------------------------------
		// print labels for ions that will be removed
		CASE "but_printremoveIDXWAve":
			// check waves
			IF (!Waveexists(ExpList))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - print remove Ions IDX wave button:\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcheck name of Explist wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			IF (!Waveexists(Removeions_IDX))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - print remove Ions IDX wave button:\r\rmissing wave:\r\r"+removeIons_wave_Str
				abortStr+="\r\rcheck name of Explist wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			folderPath="root:"+ExpList[0]+":"
			folderPath=replaceString("root:root",folderPath,"root")
	
			Wave/Z/T ionLabel=$(folderPath+WaveNames[%LabelName])// wave with ion labels for first Explist entry
			
			IF (!Waveexists(ionLabel))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - print remove Ions IDX wave button:\r\rion label wave not found in folder:\r"+explist[0]
				abortStr+="\rcheck content of expList wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			Extract/FREE ionLabel,removedions,Removeions_IDX==1
			Extract/FREE/INDX ionLabel,IDX_removedions,Removeions_IDX==1
			
			print "--------------"
			print "these ions will be removed for the combined data set"
			print removedIons
			print IDX_removedions
			print "--------------"
			BREAK
			
		//----------------------------------	
		// set ion to be removed in give IDX wave )=1)
		CASE "but_removeIonIDX":
			// check waves
			IF (!Waveexists(ExpList))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - remove Ions IDX wave button:\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcheck name of Explist wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			// check existing removeIDXwave
			MPaux_check_removeIonsIDXWave(removeIons_wave_Str,ExpList_str,WaveNames[%MZname])
						
			// set value for ion
			Wave/Z/T ionLabel=$("root:"+explist[0]+":"+WaveNames[%LabelName])// wave with ion labels for first Explist entry

			ionIDX=MPaux_getIonIDX(ionLabel)
			Removeions_IDX[ionIDX]=1
			
			BREAK
			
		//----------------------------------	
		// set ion to be included in give IDX wave (=0)
		CASE "but_includeIonIDX":
			// check waves
			IF (!Waveexists(ExpList))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - include Ions IDX wave button:\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcheck name of Explist wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			// check existing removeIDXwave
			MPaux_check_removeIonsIDXWave(removeIons_wave_Str,ExpList_str,WaveNames[%MZname])
			
			// set value for ion
			Wave/Z/T ionLabel=$("root:"+explist[0]+":"+WaveNames[3])// wave with ion labels for first Explist entry

			ionIDX=MPaux_getIonIDX(ionLabel)
			
			Removeions_IDX[ionIDX]=0
			
			BREAK
		//----------------------------------	
		// remove ions for all but FIGAERO-TD data
		CASE "but_removeIons_doit":
			// basic check
			Variable ignoreErr=0
			IF (stringmatch(Wavenames[%MSerrname],""))
				ignoreErr=1
			ENDIF
			MPaux_checkPMFWaves(Combiname_Str,waveNames,1,ignoreErr=ignoreErr)
			
			// info from Panel
			IF (!Waveexists(Removeions_IDX))
				Setdatafolder $oldFolder
				
				abortStr="MPbut_step1_button_control - Do it button:\r\rmissing wave:\r\r"+removeIons_wave_Str
				abortStr+="\r\rcheck name of Explist wave"
				MPaux_abort(AbortStr)
			ENDIF
			
			SVAR Suffix=root:app:removeIons_suffix_Str
			IF (Stringmatch(suffix,""))	// catch empty suffix
				abortStr="MPbut_step1_button_control - Do it button:\r\rempty suffix string passed. Please provide a valid suffix to add to the basic wavenames."
				MPaux_abort(abortSTr)
			ENDIF
			// check for "liberal name"
			String orgSuffix="a"+suffix	// catch if suffix is a number or _
			String legalSuffix=CleanupName(orgSuffix,0)
			IF (!Stringmatch(orgsuffix,legalSuffix))
				abortStr="MPbut_step1_button_control - Do it button:\r\rSuffix will create illegal wave names. Check suffix:\r\r"+suffix
				MPaux_abort(abortSTr)
			ENDIF
			// create text wave with names (ignore Mserr if field is empty)
			Make/T/FREE/N=(4) Waves4removal
			SetDImlabel 0,0,MSdataname,Waves4Removal
			SetDImlabel 0,1,LabelName,Waves4Removal
			SetDImlabel 0,2,MZname,Waves4Removal
			SetDImlabel 0,3,MSerrname,Waves4Removal
			
			Waves4removal[%MSdataname]=Wavenames[%MSdataname]
			Waves4removal[%LabelName]=Wavenames[%LabelName]
			Waves4removal[%MZname]=Wavenames[%MZname]
			Waves4removal[%MSerrname]=Wavenames[%MSerrname]
			
			IF (stringmatch(Wavenames[%MSerrname],""))
				redimension /N=(3) Waves4Removal
			ENDIF
			
			// remove ions
			MPprep_removeIons(Combiname_Str,suffix,Waves4removal,Removeions_IDX)
			
			BREAK
	
		//----------------------------------	
		// run makeCombi()
		CASE "but_runMakeCombi":
			
			// check if waves exist
			// expList wave
			IF (!Waveexists($ExpList_Str))
				abortStr="MPbut_step1_button_control - MakeCombi button\r\rmissing wave:\r\r"+ExpList_Str
				abortStr+="\r\rcannot execute makeCombi() without this wave"
			ENDIF
			
			// check if all folders in ExpList wave exist
			IF (MPaux_CheckExpListFolders(ExpList_Str)!=1)
				Wave NonExistIdx
				Setdatafolder $oldFolder
						
				abortStr="MPbut_step1_button_control - prep data button:\r\runable to find at least one folder selected in ExpList Wave:\r\r"
				FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
					abortStr+=Explist[NonExistIdx[ii]]+"\r"
				ENDFOR
				abortStr+="compare entries in ExpList wave with names in data browser for typos"
				MPaux_abort(AbortStr)
			ENDIF

			// removeIons
			IF (!Waveexists(Removeions_IDX))
				ALertStr="IndexWave for removeIons operation missing.\rContinue without removing Ions?"
				DoALert 1,alertStr
				
				IF (V_flag==0)	// cancel
					Setdatafolder $oldFolder
					abort
				ELSE
					// make idx wave from first entry in Explist
					// ion label
					folderPath="root:"+ExpList[0]+":"
					folderPath=replaceString("root:root",folderPath,"root")
	
					Wave/Z/T ionLabel=$(folderPath+WaveNames[%LabelName])// wave with ion labels for first Explist entry
			
					IF (!Waveexists(ionLabel))	//Wave is missing
						Setdatafolder $oldFolder
						
						abortStr="MPbut_step1_button_control - MakeCombi button\r\rmissing Wave: \r\r"+expList[0]+":"+wavenames[3]
						abortStr+="\r\rcannot execute makeCombi() without this wave"
						MPaux_abort(AbortStr)
					ELSE
						// make dummy wave and set to 0
						Make/D/O/N=(numpnts(ionLabel)) $(removeIons_wave_Str)
						Wave RemoveIons_IDX=$removeIons_wave_Str
						removeIons_IDX=0
					ENDIF
				ENDIF
				
			ENDIF
			
			// check for MSerr wave name
			//MPaux_CheckMSerrName(Wavenames)
			
			// make the combined data set
			MPprep_makeCombi(combiName_STR,ExpList,Wavenames,2,removeIDXWave=Removeions_IDX)
			
			BREAK

		DEFAULT:			// optional default expression executed
			Setdatafolder $oldFolder
			abortStr="MPbut_step1_button_control():\r\runable to identify button type\rCheck code in:\r\r'Step1_button_control'"
			MPaux_abort(AbortStr)
	ENDSWITCH
ENDIF

Setdatafolder $oldFolder
	
END


//======================================================================================
//======================================================================================
// controls for step 2 buttons

FUNCTION MPbut_step2_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct

// get globals and waves
SVAR abortStr=root:APP:abortStr				// string with abort info
SVAR ExpList_Str=root:APP:ExpList_Str		// name of wave with expfolders
SVAR removeIons_wave_Str=root:APP:removeIons_wave_Str	//name of wave with 0/1 for remove ions
SVAR Combiname_Str=root:APP:combiname_Str	// name of combi datafolder (target for makeCombi()
SVAR SGerrorFolderName=root:app:SGerrorFolderName	// name of folder with SG error data for PL error parameter fit
						
Wave/Z cbValues_prepData=root:app:cbvalues_prepData				// check box values
Wave/Z radioValues_removeIons=root:app:radioValues_removeIons	//radio button settings

Wave/Z/T ExpList=$ExpList_Str								// Explist wave
Wave/T/Z OriginalNames=root:App:OriginalWaveNames	// wave with names of original waves
Wave/T/Z WaveNames=root:App:DataWavenames				// wave with names of PMF waves
Wave/Z Removeions_IDX=$removeIons_wave_Str				// wave with removeIon IDX

NVAR removeions_IDX_Var=root:app:removeions_IDX_Var			// ion idx for current ion in removeIons action
SVAR removeions_IDX_label=root:app:removeIons_label_Str		// ion label for current ion in removeIons action

NVAR MSType_VAR=root:app:MSType_VAR

Variable oldResolution

//-----------------------

String oldfolder=getdatafolder(1)
setdatafolder root:

IF(ctrlStruct.eventCode==2)	// only execute when releasing mouse button

	// check for Wavenames Wave
	IF (!Waveexists(Wavenames))
		abortSTr="step2_button_control():\r\rSomething is very wrong: Wavenames wave does not exists. Recreate FIT-PET panel to fix this."
		MPaux_abort(AbortStr)
	ENDIF
	
	// check for colons at end of folder names
	Combiname_Str=removeending(Combiname_Str,":")
	SGerrorFolderName=removeending(SGerrorFolderName,":")
										
	// check which button was pressed
	STRSWITCH(ctrlStruct.ctrlName)	// string switch		
		//----------------------------------	
		// open PET and contiue there
		CASE "but_openPETprep":

			// bring panel to front or make new one
			doWindow/F PMF_PerformCalc_Panel

			IF (!V_flag)
				// set Panel resolution
				Execute/Q/Z "SetIgorOption PanelResolution=?"
				oldResolution = V_Flag
				Execute/Q/Z "SetIgorOption PanelResolution=72"

				pmfCalcs_makeGlobals()				
				pmfCalcs_makePanel()
				
				// reset Panel resolution to default
				Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

			ENDIF
			
			MPprep_TransferWavenames2PET(combiName_str,Wavenames)
					
			// set tab to prep or run
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

			BREAK
		
		//----------------------------------	
		// check if PMF waves exist in combi data folder
		
		CASE "but_checkWaves":
			
			// check if waves and combi folder exist
			MPaux_checkPMFWaves(combiName_str,Wavenames,0)
			
			BREAK
		
		//----------------------------------	
		// check data matrix for ions whihc are XX% negative in a sample
		
		CASE "but_handleNegValues":
			print "------------------------"
			print date() +" "+time()+" checking data for PMF run:"
			// check if waves and combi folder exist
			MPaux_checkPMFWaves(combiName_str,Wavenames,0)
			
			// identify and handle mostly negative ions
			NVAR negValueThreshold_VAR=root:APP:negValueThreshold_VAR
			
			MPprep_checkNegIons(combiName_str,Wavenames,negValueThreshold_VAR,Explist)
			
			BREAK
				
		//----------------------------------	
		
		// look for columns of 0 or NaNs in data matrix and find 0/NaNs in error Matrix
		CASE "but_handleNaNs":
			print "------------------------"
			print date() +" "+time()+" checking data for PMF run:"
			
			// check if waves and combi folder exist
			MPaux_checkPMFWaves(combiName_str,Wavenames,0)
			
			Wave MSerr=$(combiName_str+":"+WaveNames[%MSerrName])
			
			// check MSerr matix	(do this first)
			MPprep_CheckMSerr4Nan(MSerr)
			
			// check MSdata martix (this may remove columns or rows)
			MPprep_checkMSdata4NaN(combiName_str,WaveNames,ExpList)
			
			BREAK
		
		//----------------------------------	
		// open SNR analysis Panel included in PET 3.08 		
		CASE "but_showSNRpanel":
			
			// check that all waves exist
			MPaux_checkPMFWaves(combiName_str,Wavenames,1)
			
			// kill existing panel
			Killwindow/Z SNRAnal
			
			// set PET globals with Wavenames from FITPET Panel
			// check if PMF_prep_global vaiables exist
			SVAR DataMxNm_last = root:pmf_prep_globals:DataMxNm_last
			IF (!SVAR_Exists(DataMxNm_last))
				pmfCalcs_makeGlobals()
			ENDIF
			
			SVAR pmfDFnm = root:pmf_prep_globals:pmfDFnm
			SVAR DataMxNm_last = root:pmf_prep_globals:DataMxNm_last
			SVAR DataMxNm = root:pmf_prep_globals:DataMxNm
			SVAR ErrMxNm_last = root:pmf_prep_globals:ErrMxNm_last
			SVAR ErrMxNm = root:pmf_prep_globals:ErrMxNm
			SVAR rowDescrWvNm_last = root:pmf_prep_globals:rowDescrWvNm_last
			SVAR colDescrWvNm_last = root:pmf_prep_globals:colDescrWvNm_last
			SVAR/Z colDescrTxtWvNm_last = root:pmf_prep_globals:colDescrTxtWvNm_last
			
			if(!SVar_exists(colDescrTxtWvNm_last))	// catch if new PET did not make the colDescrTxtWvNm_last variable
				SVAR colDescrTxtWvNm_last = root:pmf_prep_globals:colDesTxtWvNm_last
			endif
			
			// make sure they are set to FITPET panel values
			pmfDFnm=combiName_str+":"	// must have colon at the end
			DataMxNm_last=WaveNames[%MSdataname]
			DataMxNm=WaveNames[%MSdataname]
			ErrMxNm_last=WaveNames[%MSerrName]
			ErrMxNm=WaveNames[%MSerrName]
			rowDescrWvNm_last=WaveNames[%Tname]
			colDescrWvNm_last=WaveNames[%MZname]
			colDescrTxtWvNm_last=WaveNames[%LabelName]
			
			// skip storing wavenames from PET panel (which will not work if no PET Panle is open)
			NVAR storedWvNms = root:pmf_prep_globals:storedWvNms
			storedWvNms=1
			
			// call panel
			// set Panel resolution
			Execute/Q/Z "SetIgorOption PanelResolution=?"
			oldResolution = V_Flag
			Execute/Q/Z "SetIgorOption PanelResolution=72"

			SNRAnalysis#pmf_viewSNRPanel(ctrlStruct)
			
			// reset Panel resolution to default
			Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

			BREAK
		
		//----------------------------------			
		// use values from Panel to apply sample by sample downweighing of data
		CASE "but_downweigh":
				
			// check if waves and combi folder exist
			MPaux_checkPMFWaves(combiName_str,Wavenames,1)
			
			// get values from Panel
			NVAR SNRthreshold=root:APP:SNRthreshold_var
			NVAR weakDownweigh=root:APP:weakDownweigh_VAR
			
			// check error wave name
			Wavenames[1]=removeending(Wavenames[1],"Wk")
			
			// run downweighing routine
			MPprep_calcSNR_CombiData(CombiName_Str, wavenames,weakDownweigh,SNRthreshold)
			
			BREAK
		
		//----------------------------------			
		// use new Path to set the folder path for the PMT exe file
		CASE "but_getExePath":
			
			SVAR PMFexeFilename = root:APP:PMFexeFilename_STR
			SVAR pmf_exePathStr =root:APP:DisplayPMFexePath_STR
			
			// check if different filename is set in PET
			SVAR PMFexeFilename_PET=root:pmf_calc_globals:PMFexefilename
			String currentPMFexeFilename=PMFexeFilename
			
			IF (!stringmatch(PMFexeFilename,PMFexeFilename_PET))
				String Alert_exefile="pmf2_____.exe file names do not agree in MaS-PET and PET.\rContinue with:"
				Alert_exefile+="\r\r"+PMFexeFilename+ " (YES)"
				Alert_exefile+="\r\r"+PMFexeFilename_PET+" (NO)"
				Doalert 2,alert_exefile
				
				IF (V_flag==1)
					//yes -> use MaS-PET
					currentPMFexeFilename=PMFexeFilename
				ENDIF
				IF (V_flag==2)
					//no -> use PET
					currentPMFexeFilename=PMFexeFilename_PET
				ENDIF
				IF (V_flag==3)
					//Cancel
					Abort
				ENDIF

			ENDIF
	
			// ! this is copied from PET !
			NewPath/Q/o/M="Please select the directory where the PMF executable file named "+currentPMFexeFilename+" resides." $PMF_EXE_IGOR_PATH_NAME			// the name of the path where the PMF executable file lives.
			
			IF (V_flag==0)		// success
				// check if exe file exists
				
				String fileList, fileStr
				Variable fileIndex, fileNum, ExecutableExistsSuccess=0
			
				PathInfo $PMF_EXE_IGOR_PATH_NAME
				if (!V_flag)
					Setdatafolder $oldFolder
					abort "Please reselect the path to the PMF executable file.  Aborting from pmfCalcs_DoesExeExist()"
				endif
				
				// Check to see if executable lives there.
				fileIndex=0
				do
					fileStr = IndexedFile($PMF_EXE_IGOR_PATH_NAME, fileIndex,  ".exe")
					if (stringmatch(lowerstr(fileStr),lowerstr(currentPMFexeFilename) ) ) //imu2.05 updated to PMFexeFilename
						ExecutableExistsSuccess=1
					endif
					
					fileIndex+=1
					
				while(strlen(FileStr)>0 && ExecutableExistsSuccess==0)	

				// save path to variable if found
				PathInfo $PMF_EXE_IGOR_PATH_NAME
				
				IF (ExecutableExistsSuccess==1)
					// exe was found
					pmf_exePathStr=S_path
					
					// adjust file names if they were different
					
					IF (!stringmatch(PMFexeFilename,PMFexeFilename_PET))
						PMFexeFilename=currentPMFexeFilename
						PMFexeFilename_PET=currentPMFexeFilename
					ENDIF
					
				ELSE
					// exe not found
					// print ot history(easier to check filename/path later :-)
					print "-------------------"
					print date() +" "+time()+ " looking for PMF2 exe file"
					print "PMF exe file: "+ currentPMFexeFilename + " not found in folder: "+S_path
					print "If you want to use a different file name, go to 'PMF defaults' tab on the PET panel."
					print "Select the desired file name there. Close the PET panel and try again with 'get exe'."
					
					// and popup dialog
					String ExeNotfound="PMF exe file: "+ currentPMFexeFilename + " not found in folder: \r"+S_path
					ExeNotfound+="\r\rNew path is not set!"
					ExeNotfound+="\r\rCheck filename in folder and go to 'PMF defaults' tab on the PET panel to change the PMF exe file name if necessary."
					MPaux_abort(Exenotfound)
				ENDIF
				
			ENDIF

			BREAK
			
		//----------------------------------			
		// RUN PMF
		CASE "but_runPMF":
			
			// put all the values into PET globals
			// PET globals
			String PET_names="p_min;p_max;fpeak_Method;fpeak_min;fpeak_max;fpeak_delta;SeedOrFpeak;"
			PET_names+="saveExpAfterPMF;pmfModelError;exploreOrBootstrap;PMFexeFilename;fpeak_methodStr;"
			PET_names+="maxCumStepsLevel1;maxCumStepsLevel2;maxCumStepsLevel3;runPMFinBackground;SeedOrFPeak;"
			
			//MaS-PET globals
			String APP_names="p_min_VAR;p_max_VAR;fpeak_Method_VAR;fpeak_min_VAR;fpeak_max_VAR;fpeak_delta_VAR;SeedOrFpeak_VAR;"
			APP_names+="saveExpAfterPMF_VAR;pmfModelError_VAR;exploreOrBootstrap_VAR;PMFexeFilename_STR;fpeak_methodStr_STR;"
			APP_Names+="maxCumStepsLevel1_VAR;maxCumStepsLevel2_VAR;maxCumStepsLevel3_VAR;runPMFinBackground_VAR;SeedOrFPeak_VAR;"

			MPaux_transferPMFparams("APP",APP_names,"pmf_calc_globals",PET_names)
			
			// check if waves and combi folder exist and wave dimensions are correct
			MPaux_checkPMFWaves(combiName_str,Wavenames,1)
			
			// copy wavenames to combi folder
			MPaux_makeWaves4PMF(combiName_Str,Wavenames)
			Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
						
			// copy explist to combi (this is the full list!)
			Make/O/T/N=(numpnts(expList)) $(Combiname_Str+":ExpList4PMF")
			Wave/T ExpList4PMF=$(Combiname_Str+":ExpList4PMF")
			ExpList4PMF=Explist
			
			// double check with user
			String AlertStr="Do you want to run PMF with the following choices?"
			alertStr+="\r\rdata folder:\t"+combiName_str
			alertStr+="\r\rWaves:"
			alertStr+="\rMS data:\t"+Waves4PMF[%MSdataname]
			alertStr+="\rMS error:\t"+Waves4PMF[%MSerrName]
			alertStr+="\rMZ values:\t"+Waves4PMF[%MZname]
			alertStr+="\rIon labels:\t"+Waves4PMF[%LAbelName]
			alertStr+="\rTdesorp:\t"+Waves4PMF[%Tname]
			
			NVAR pmin=root:APP:p_Min_VAR
			NVAR pmax=root:APP:p_Max_VAR
			NVAR fpeakmin=root:APP:fpeak_Min_VAR
			NVAR fpeakmax=root:APP:fpeak_Max_VAR
			NVAR fpeaksteps=root:APP:fpeak_delta_VAR
			NVAR SeedOrFpeak = root:pmf_Calc_globals:SeedOrFpeak		
			
			alertStr+="\r\r p = "+num2str(pmin)+" - "+num2Str(pmax)

			IF (SeedORFpeak==0)	
				alertStr+="\r\r fpeak = "
			ELSE
				alertStr+="\r\r seed = "	
			ENDIF

			alertStr+=num2str(fpeakmin)+" - "+num2Str(Fpeakmax)+ " steps: "+num2str(fpeaksteps)

			// catch if alert String is getting too long for Igor 7
			IF (IgorVersion()<8.00)
				IF (StrLen(alertStr)>254)
					//If string too long, print to history in two goes
					String AlertStr1="Do you want to run PMF with the following choices?"
					AlertStr1+="\r\rdata folder:\t"+combiName_str
					AlertStr1+="\r\rWaves:"
					AlertStr1+="\rMS data:\t"+Waves4PMF[%MSdataname]
					AlertStr1+="\rMS error:\t"+Waves4PMF[%MSerrName]
					AlertStr1+="\rMZ values:\t"+Waves4PMF[%MZname]
					AlertStr1+="\rIon labels:\t"+Waves4PMF[%LAbelName]
					AlertStr1+="\rTdesorp:\t"+Waves4PMF[%Tname]
					
					String AlertStr2="p = "+num2str(pmin)+" - "+num2Str(pmax)
					IF (SeedORFpeak==0)	
						AlertStr2+="\r\r fpeak = "
					ELSE
						AlertStr2+="\r\r seed = "	
					ENDIF
					AlertStr2+=num2str(fpeakmin)+" - "+num2Str(Fpeakmax)+ " steps: "+num2str(fpeaksteps)

					print "----------------------------------------------"
					print alertStr1
					print alertStr2
					
					alertStr="Do you want to run PMF with the following choices?"
					alertStr+="\r(Full details in History Window)"
					AlertStr+="\rdata folder:\t"+combiName_str
					alertStr+="\r\r"+alertStr2

				ENDIF	
			ENDIF			
			
			DoAlert 1, alertStr
			
			IF (V_flag==1)
				// start calculation
				print "----------------------------------------------"
				print date()+" "+time() +" starting PMF calcaulations:"
				MPaux_RUN_PMF()
			
				// store solution space info (only if calcualtion was done)
				MPaux_makePMFSolInfo(combiName_Str,useMStype=1)
			
			ENDIF
			
				
			BREAK
		
		//-----------------------------
		DEFAULT:			// optional default expression executed
			Setdatafolder $oldFolder
			abortStr="step2_button_control():\r\runable to identify button type\rCheck code in:\r\r'Step1_button_control'"
			MPaux_abort(AbortStr)
	ENDSWITCH
ENDIF

Setdatafolder $oldFolder

END

//======================================================================================
//======================================================================================
// controls for step 3 buttons (but not the plotting ones)

FUNCTION MPbut_step3_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct

IF(ctrlStruct.eventCode==2)	// only execute when releasing mouse button
	
	// get globals and waves
	SVAR abortStr=root:APP:abortStr				// string with abort info
	SVAR ExpList_Str=root:APP:ExpList_Str		// name of wave with expfolders
	SVAR removeIons_wave_Str=root:APP:removeIons_wave_Str	//name of wave with 0/1 for remove ions
	SVAR Combiname_Str=root:APP:combiname_Str	// name of combi datafolder (target for makeCombi())
	SVAR SGerrorFolderName=root:app:SGerrorFolderName	// name of folder with SG error data for PL error parameter fit
	
	SVAR/Z SolutionFolder=root:APP:SolutionFolder_STR
							
	Wave/Z cbValues_prepData=root:app:cbvalues_prepData				// check box values
	Wave/Z radioValues_removeIons=root:app:radioValues_removeIons	//radio button settings
	
	Wave/Z/T ExpList=$ExpList_Str								// Explist wave
	Wave/T/Z OriginalNames=root:App:OriginalWaveNames	// wave with names of original waves
	Wave/T/Z WaveNames=root:App:DataWavenames				// wave with names of PMF waves
	Wave/Z Removeions_IDX=$removeIons_wave_Str				// wave with removeIon IDX
	
	NVAR removeions_IDX_Var=root:app:removeions_IDX_Var			// ion idx for current ion in removeIons action
	SVAR removeions_IDX_label=root:app:removeIons_label_Str		// ion label for current ion in removeIons action
	
	NVAR MStype_var=root:APP:MStype_var	// type of MS data
				
	String oldfolder=getdatafolder(1)
	setdatafolder root:

	// check for Wavenames Wave
	IF (!Waveexists(Wavenames))
		abortSTr="MPbut_step3_button_control():\r\rSomething is very wrong: Wavenames wave does not exists. Recreate MaS-PET panel to fix this."
		MPaux_abort(AbortStr)
	ENDIF

	// check for extra ':' at end of folderName strings
	SolutionFolder=removeEnding(SolutionFOlder,":")
	Combiname_Str=removeending(Combiname_Str,":")
	SGerrorFolderName=removeending(SGerrorFolderName,":")
	
	// waves with wave names and sample list						
	Wave/T/Z Waves4PMF=$(Combiname_Str+":Waves4PMF")	// wavenames saved for PMF run		
	Wave/T/Z ExpList4PMF=$(Combiname_Str+":ExpList4PMF")	// ExpList saved for PMF run		
	
	// general variables/strings
	Variable ii
	String labelDummy
	String Waves4PMF_list=""
	
						
	//---------------------------------
	// check which button was pressed
	STRSWITCH(ctrlStruct.ctrlName)	// string switch		

		//----------------------------------			
		// open panel without popup panel using wavenames from APP
		CASE "but_openPETresult":
			
			// check if combi folder exists
			IF (!datafolderexists(combiname_Str))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + Combiname_Str+ "\rfolder does not exist"
				MPaux_abort(AbortStr)	
			ENDIF
			
				
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(combiname_Str,ctrlStruct.ctrlName,Wavenames)
			Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
					
			// check for idxSample wave
			Wave Tdesorp=$(combiname_str+":"+Waves4PMF[%Tname])
			IF (waveexists(TDesorp))	// if wave does not exist (=wrong name in Panel) go to next check to trigger proper abort

				// check for Explist first
				IF (!Waveexists(Explist4PMF))
					// if Main panel selection exists -> copy that one
					IF (Waveexists(EXpList))
						
						print "-------------------------"
						print date()+" "+time() +" checks before extracting solution:"
						print "no ExpList4PMF wave found in folder with PMF calcualtions -> copying wave given in Main Panel"
						print Combiname_Str+":ExpList4PMF"
						
						// check if number of entries agrees with idxSample wave
						Make/T/O/N=(numpnts(Explist)) $(Combiname_Str+":ExpList4PMF")
						Wave/T Explist4PMF=$(Combiname_Str+":ExpList4PMF")
						Explist4PMF=Explist
						
					ELSE
						// if main Panel entry does not exist
							
						abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r"
						abortStr+="No Explist4PMF found and ExpList given in Main Panel does not exist.\"rSelect a valid ExpList in the Main Panel and try again."
						MPaux_abort(abortStr)
						
					ENDIF
				ENDIF

				MPaux_check4IDXSample(Waves4PMF[%idxSampleName],Combiname_Str,Tdesorp,ExpList4PMF)

			ENDIF
			
			// check if waves and combi folder exist
			// also checks if dimensions agree
			MPaux_checkPMFWaves(combiName_str,Waves4PMF,1)
			
			// check for PMFsolinfo wave (not needed but good to have)
			IF (!Waveexists($(combiName_str+":PMFSolInfo")))
				MPaux_makePMFSolInfo(combiName_Str)
			ENDIF
			
			// make sure globals exist
			pmfResults_makeGlobals()				
			
			// check on datatype and capture vaporizer variables
			NVAR/z dataTypeHR = root:pmf_plot_globals:dataTypeHR	
			IF (!NVar_exists(dataTypeHR))
				Variable/G root:pmf_plot_globals:dataTypeHR=0
			ENDIF
			// get value from APP folder
			NVAR dataTypeHR_VAR=root:APP:datatypeHR_VAR
			dataTypeHR=dataTypeHR_VAR

			NVAR/z CapVapFLag = root:pmf_plot_globals:CapVapFLag	
			IF (!NVar_exists(CapVapFLag))
				Variable/G root:pmf_plot_globals:CapVapFLag=0
			ENDIF
			// get value from APP folder
			NVAR CapVapFLag_VAR=root:APP:CapVapFLag_VAR
			CapVapFLag=CapVapFLag_VAR
			 
			// open panel without popup panel using wavenames from APP
			MPpost_openPETresults()
			
			// open single ion compare graph
			MPaux_FIT_FactorIonTS_Main(combiName_str)
			
			BREAK
		
		//----------------------------------			
		// open reconstructed ion thermogram Panel
		CASE "but_FactorIonThermo":
			
			// check if combi folder exists
			IF (!datafolderexists(combiname_Str))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + Combiname_Str+ "\rfolder does not exist"
				MPaux_abort(AbortStr)	
			ENDIF
			
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(combiname_Str,ctrlStruct.ctrlName,Wavenames)
			Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
			
			// check if waves and combi folder exist
			// also checks if dimensions agree
			MPaux_checkPMFWaves(combiName_str,Waves4PMF,1)
				
			// open single ion compare graph
			MPaux_FIT_FactorIonTS_Main(combiName_str)
			
			BREAK	
			
		//----------------------------------			
		// calculate (un)explained variance for all solutions&fpeaks/seeds
		
		CASE "but_calcVariance":
			// check if combi folder exists
			IF (!datafolderexists(combiname_Str))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + Combiname_Str+ "\rfolder does not exist"
				MPaux_abort(AbortStr)	
			ENDIF
			
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(combiname_Str,ctrlStruct.ctrlName,Wavenames)
			Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
			
			// check if waves are there
			MPaux_checkPMFWaves(combiName_str,Waves4PMF,1)
			
			// get calculation type
			NVAR VarianceType_VAR=root:APP:VarianceType_VAR
			// calcualte variance
			MPpost_calcExpVariance(combiName_str,Waves4PMF[%MSdataName],VarianceType_VAR)	// 1: use sum of abs 0: use sum of squares
		
			BREAK
		
		//----------------------------------			
		// extract solution
			
		CASE "but_getSolution":
			NVAR nSol=root:APP:p4getSolution_VAR
			NVAR fpeak=root:APP:fpeak4getSolution_VAR

			// check if combi folder exists
			IF (!datafolderexists(combiname_Str))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + Combiname_Str+ "\rfolder does not exist"
				MPaux_abort(AbortStr)	
			ENDIF
			
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(combiname_Str,ctrlStruct.ctrlName,Wavenames)
			Wave/T Waves4PMF=$(Combiname_Str+":Waves4PMF")
			
			// extract one solution (NOTE: using explist wave that was saved in combi folder when PMF run was clicked)
			Wave cbValues_prepData=root:app:cbValues_prepData
			String Explist4PMF_str=Combiname_Str+":ExpList4PMF"
			
			// check if Explist4PMF was saved in folder -> copy current Explist from Panel
			IF (!Waveexists(Explist4PMF))
				// if Main panel selection exists -> copy that one
				IF (Waveexists(EXpList))
					
					print "-------------------------"
					print date()+" "+time() +" checks before extracting solution:"
					print "no ExpList4PMF wave found in folder with PMF calcualtions -> copying wave given in Main Panel"
					print ExpList_Str
					
					// check if number of entries agrees with idxSample wave
					Make/T/O/N=(numpnts(Explist)) $(Combiname_Str+":ExpList4PMF")
					Wave/T Explist4PMF=$(Combiname_Str+":ExpList4PMF")
					Explist4PMF=Explist
					
				ELSE
					// if main Panel entry does not exist
						
					abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r"
					abortStr+="No Explist4PMF found and ExpList given in Main Panel does not exist.\"rSelect a valid ExpList in the Main Panel and try again."
					MPaux_abort(abortStr)
					
				ENDIF
			ENDIF
			
			MPpost_getSolution(Explist4PMF_str,combiName_str,nSol,fpeak,Waves4PMF,cbValues_prepData[%noplot4getSolution],MStype_var)
		
			// calculate "VBS like things"
			SVAR SolutionFolder=root:APP:SolutionFolder_STR	// call again because MPpost_getSolution() will have changed it
			
			//Tmax - Cstar calibration params store them with solution
			Wave TmaxCstarCal_values=root:App:TmaxCal:TmaxCstarCal_values
			
			Make/D/O/N=(2) $(SolutionFolder+":TmaxCstarCal_values")
			Wave TmaxCstarCal_Params=$(SolutionFolder+":TmaxCstarCal_values")
			TmaxCstarCal_Params=TmaxCstarCal_values
			
			String NoteStr="calibration parameters for Tdesorp[C]->logCstar conversion:\r"
			NoteStr+="psat = exp(param[0]+param[1]*Tdesorp)\r"
			NoteStr+="logCstar = psat*MW[g/mol]*1e6/(R*T)"
			Note TmaxCstarCal_Params,NoteStr
			
			MPpost_calcFactorContrib(SolutionFolder,Explist4PMF_str,0,TmaxCstarCal_Params,MStype_VAR,quiet=1)// turn of VBS plot for MaS-PET cbValues_prepData[%noplot4getSolution]
			
			BREAK
		
		//-------------------------------	
		// recalculate Tmax->Cstar for active solution (that is without exporting it again)
		CASE "but_recalcTmaxCstar":
			
			Wave TmaxCstarCal_values=root:App:TmaxCal:TmaxCstarCal_values
						
			MPpost_recalcTmaxCstar(SolutionFolder,TmaxCstarCal_values)
		
			BREAK
		
		//-------------------------------	
		// show the wave containing the paths to the comparison solutions
		
		CASE "but_showCompareWave":
			
			SVAR CompWaveName=root:app:CompWaveName_STR
			
			// make dummy if wave does not exist
			IF (!Waveexists($CompWaveName))
				print "---------------"
				print "Comparison wave did not exist -> creating new one"
				Make/T/N=0 $CompWaveName
			ENDIF
			
			MPaux_ShowWavesAsTable(CompWaveName,"CompareSoltutions")
			BREAK
		
		//-------------------------------	
		// compare multiple PMF solutions with base case -> factor MS
		CASE "but_compareMS":
			SVAR CompWaveName=root:app:CompWaveName_STR
			//SVAR SolutionFolder=root:APP:SolutionFolder_STR
			
			String OutFolder=SolutionFolder+":"+"C_"+Stringfromlist(Itemsinlist(CompWaveName,":")-1,CompWaveName,":")
			
			MPpost_comparePMFsolutions(SolutionFolder,CompWaveName,OutFOlder,"MS")
			BREAK
			
		//----------------------------------			
		// compare multiple PMF solutions with base case -> residual as tseries
		CASE "but_compareResidual_tseries":
			SVAR CompWaveName=root:app:CompWaveName_STR
			//SVAR SolutionFolder=root:APP:SolutionFolder_STR
			
			// check if solution data folder exists
			IF (!datafolderexists(SolutionFolder))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + SolutionFolder+ "\rfolder does not exist"
				MPaux_abort(AbortStr)		
			ENDIF
			
			// switch to Waves4PMF in active solution folder
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(solutionFolder,ctrlStruct.ctrlName,Wavenames)			
			Wave/T Waves4PMF=$(solutionFolder+":Waves4PMF")
				
			MPpost_comparePMFresidual(solutionFolder,CompWavename,Waves4PMF,0)
			
			BREAK
			
		//----------------------------------			
		// compare multiple PMF solutions with base case -> residual as tseries
		CASE "but_compareResidual_MS":
			SVAR CompWaveName=root:app:CompWaveName_STR
			//SVAR SolutionFolder=root:APP:SolutionFolder_STR
			
			// check if solution data folder exists
			IF (!datafolderexists(SolutionFolder))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + SolutionFolder+ "\rfolder does not exist"
				MPaux_abort(AbortStr)		
			ENDIF
			
			// switch to Waves4PMF in active solution folder
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(solutionFolder,ctrlStruct.ctrlName,Wavenames)			
			Wave/T Waves4PMF=$(solutionFolder+":Waves4PMF")
				
			MPpost_comparePMFresidual(solutionFolder,CompWavename,Waves4PMF,1)
			
			BREAK
		//----------------------------------			

		CASE "but_exportSolution":
			
			// Check if solution folder exists 
			IF (!datafolderexists(SolutionFolder))
				abortStr="MPbut_step3_button_control: - "+ctrlStruct.ctrlName+"\r\r" + SolutionFolder+ "\rfolder does not exist"
				MPaux_abort(AbortStr)		
			ENDIF
		
			// switch to Waves4PMF in active solution folder
			// check for Waves4PMF and create if missing	
			MPaux_check4Waves4PMF(solutionFolder,ctrlStruct.ctrlName,Wavenames)			
			Wave/T Waves4PMF=$(solutionFolder+":Waves4PMF")
								
			// use current solution folder from APP			
			SVAR Solution4TXTExport=root:APP:SolutionFolder_STR
			// get MS type from Panel
			NVAR MStype=root:APP:MStype_VAR
			
			// get info about timeformat
			NVAR exportTimeType=root:APP:exportTimeType_VAR	// 0: none or igor sec, 1: Matlab, 2:text
			SVAR timeformatStr=root:APP:exportTimeformat_STR	// format string
			
			// check for including original data
			Wave cbvalues_prepData=root:app:cbvalues_prepData
			Variable includeOriginal=cbvalues_prepData[%includeOriginal]
			
			// export
			MPpost_exportSolution2txt(Solution4TXTexport,Waves4PMF,MStype,exportTimeType,timeformatStr,includeOriginal)
			
			BREAK
		//----------------------------------			

		DEFAULT:			// optional default expression executed
			Setdatafolder $oldFolder
			abortStr="MPbut_step3_button_control():\r\runable to identify button type\rCheck code in:\r\r'Step3_button_control'"
			MPaux_abort(AbortStr)
			
	ENDSWITCH

	// reset to old datafolder
	Setdatafolder $oldFolder


ENDIF


END

//======================================================================================
//======================================================================================
//  BUttons in data loader Panel

FUNCTION MPbut_DL_DataLoad_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct

// check which button was pressed
IF(ctrlStruct.eventCode==2)	// only execute when releasing mouse button

	String oldfolder=getdatafolder(1)
	
	SVAR abortStr=root:APP:abortStr								// string with abort info
	SVAR LoadFolderName=root:APP:dataloader:LoadFolderName_STR

	STRSWITCH (ctrlStruct.ctrlName)
	
		// browse for a folder in Explorer
		CASE "but_browseFolder":
			
			SVAR PATH_dataloader_str=root:APP:dataloader:PATH_dataloader_STR								// string with abort info

			Pathinfo/S PATH_dataloader
			NewPath/Q/O/M="Select folder with files for loading" PATH_dataloader			
			
			// store new Path name in String
			IF (V_flag==0)
				Pathinfo PATH_dataloader
				LoadFolderName=S_path
				PATH_dataloader_str=S_path	//store
			ENDIF
			
			BREAK
		
		// start the loading
		CASE "but_dataLoader":
		
			// get info from Panel
			NVAR loadFileType_VAR=root:APP:dataloader:loadFileType_VAR
			NVAR loadSampleType_VAR=root:APP:dataloader:loadSampleType_VAR
			NVAR loadDelimType_VAR=root:APP:dataloader:loadDelimType_VAR
			
			SVAR FileLabelList =root:APP:dataloader:FileLabelList	// labels for FileNames Wave
			
			SVAR IgorFOlder=root:APP:dataloader:IgorFolderName_STR
			SVAR LoadFOlder=root:APP:dataloader:LoadFolderName_STR
			
			Wave/T DataWaveNames=root:APP:DataWaveNames	// names Waves in Main Panel
			Wave/T FileNames=root:APP:dataloader:FIleNames	// names of files (without extension)
			Wave/T FileExtensions=root:APP:dataloader:FileExtensions	// Fileextensions
			
			// get chosen wavenames
			Make/O/T/N=(8) root:APP:dataLOader:LoadedWaveNames=""	// names for the loaded waves
			Wave/T LoadedWaveNames=root:APP:dataLOader:LoadedWaveNames
			
			Make/O/T/N=1 root:APP:dataLOader:tempWave	// for storage
			Wave/T tempWave=root:APP:dataLOader:tempWave
			
			Variable ii
			FOR (ii=0;ii<numpnts(FileNames)-1;ii+=1)
				
				// set LAbels on new wave
				String labelDummy=Stringfromlist(ii,FileLabelList)
				setDimLabel 0,ii,$LabelDummy,LoadedWaveNames
				
				// get names for loaded waves
				String currentVarName_Wave= "VarTxt_"+StringFromList(ii,FileLabelList)+"_wave"
	
				ControlInfo $currentVarName_Wave	// some names are linked to waves other gives name directly
				
				IF (!Stringmatch(S_value,"*[*"))
					// simple: name is stored directly
					LoadedWaveNames[ii]=S_value
				ELSE
					// "name" is a wave reference
					String ExecuteStr= "root:APP:dataloader:TempWave[0]=root:APP:"+S_value
					Execute ExecuteSTr
					
					LoadedWaveNames[ii]=tempWave[0]
					
				ENDIF
				
			ENDFOR
			Killwaves/Z tempWave		// remove temporary wave
			
			Controlinfo cb_overwrite_loader
			Variable Overwrite=V_value
			
			// do the data loading
			Setdatafolder root:APP:dataLoader
			
			MPprep_DL_DataLoader_Main(Overwrite,FileNames,FileExtensions,LoadedWaveNames)
					
			BREAK
		DEFAULT:

			Setdatafolder $oldFolder
			abortStr="MPbut_DL_DataLoad_button_control():\r\runable to identify button type\rCheck code in:\r\MPbut_DL_DataLoad_button_control'"
			MPaux_abort(AbortStr)
			BREAK
			
	ENDSWITCH

	Setdatafolder $oldFolder
ENDIF

END


//======================================================================================
//======================================================================================
// Buttons in PLerr Panel

FUNCTION MPbut_PLerrPanel_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct

// check which button was pressed
IF(ctrlStruct.eventCode==2)	// only execute when releasing mouse button

	String oldfolder=getdatafolder(1)
	
	SVAR abortStr=root:APP:abortStr								// string with abort info

	STRSWITCH (ctrlStruct.ctrlName)
	
		// calculate PL error for all sample folders in ExpList Wave
		CASE "but_doPLerr":
			MPprep_PLE_DoPLerr()
			BREAK
		
		// calculate PL error fit curve with given parameters
		CASE "but_doPLfitcalc":
			MPprep_PLE_DoPLfitcalc()
			
			BREAK
		// fit Sij values with power law
		CASE "but_doPLfit":
			MPprep_PLE_DoPLfit()
			BREAK
		// reset Data to starting values
		CASE "but_resetData":
			MPprep_PLE_ResetData()
			BREAK
			
		DEFAULT:
			Setdatafolder $oldFolder
			abortStr="MPbut_PLerrPanel_button_control():\r\runable to identify button type\rCheck code in:\r\r'MPbut_PLerrPanel_button_control'"
			MPaux_abort(AbortStr)
			
			BREAK
			
	ENDSWITCH

	Setdatafolder $oldFolder
ENDIF

END

//======================================================================================
//======================================================================================
// plotting buttons from step 3

FUNCTION MPbut_plot_button_control(ctrlStruct) : ButtonControl

STRUCT WMButtonAction &ctrlStruct

// check which button was pressed
IF(ctrlStruct.eventCode==2)	// only execute when releasing mouse button
	
	// get globals and waves
	SVAR abortStr=root:APP:abortStr								// string with abort info
	SVAR ExpList_Str=root:APP:ExpList_Str						// name of wave with expfolders
	SVAR SolutionFolder=root:APP:SolutionFolder_STR			//folder name for active solution
	SVAR unitStr=root:APP:Unit4Plot_STR
	
	// check for extra ':' at end of SOlution folder
	SolutionFolder=removeEnding(Solutionfolder,":")

	NVAR plotMS_singleF_VAR=root:APP:plotMS_singleF_VAR		//0/1 for all/single factor
	NVAR plotMS_Fnum_VAR=root:APP:plotMS_Fnum_VAR				// number of factor to plot
	NVAR plotThermo_singleS_VAR=root:APP:plotThermo_singleS_VAR	// 0/1 for all smaples or single one
	NVAR plotThermo_Snum_VAR=root:APP:plotThermo_Snum_VAR	// number of sample to plot
	NVAR plotBars_type_VAR=root:APP:plotBars_type_VAR	// plot bars with absolute or relative contributions
	NVAR plotBars_Xtype_VAR=root:APP:plotBars_Xtype_VAR		// plot as category plot vs sample labels or vs time stamps
	NVAR panelPerCol_VAR=root:APP:panelPerCol_VAR				//how many panels per column -> column number determined automatically
	
	Wave/Z/T ExpList=$ExpList_Str								// Explist wave
	String ExpList4PMF_Str=SolutionFolder+":Explist4PMF"
	
	Wave/T/Z WaveNames=root:App:DataWavenames				// wave with names of PMF waves
	Wave/T/Z Waves4PMF=$(SolutionFolder+":Waves4PMF")	// !!! this is the one in the extracted solution folder !!!	
	
	String oldfolder=getdatafolder(1)
	String FigTimeName=""
	
	// check if solutoin folder exists
	IF (!Datafolderexists(solutionfolder))
		abortStr="MPbut_plot_button_control() "+ctrlStruct.ctrlName+":\r\rcannot find given solution folder "+SolutionFolder
		MPaux_abort(AbortStr)
	ENDIF
	
	// get solution number from content
	Wave/Z aNote=$(SolutionFolder+":aNote")

	IF (!Waveexists (anote))
		abortStr=ctrlStruct.ctrlName+":\r\rcannot find Wave aNote in folder "+SolutionFolder
		print "--------------------"
		print date() +" "+time()
		print "MPbut_plot_button_control(): "+SolutionFolder+":aNote"+" Wave does not exists -> prompting user for info"

		// prompt user for info
		Variable factorNumber=0
		Variable rotValue=0
		Variable rotType=0
		
		Prompt factorNumber,"number of factors"
		Prompt rotType,"fpeak or seed?",popup,"fpeak;seed;"
		Prompt rotvalue,"fpeak or seed value"
		
		doPrompt "Provide info about solution", factorNumber,rotValue,rotType

		IF (V_flag==1)
			//user canceled
			Abort		
		ENDIF
		
		// create aNote wave
		Make/D/O/N=(3) $(SolutionFolder+":aNote")
		Wave aNote=$(SolutionFolder+":aNote")
		Note/K aNote, "solution Number\rfpeak or seed value\r0:fpeak;1:seed"
		
		aNOte[0]=factorNumber
		aNote[1]=rotvalue
		aNote[2]=rotType-1 // popup entry starts count at 1
		
	ENDIF
	
	// catch if wavenames were not saved
	IF (!waveexists(Waves4PMF))
		print "---------------"
		print date() +" "+time()
		print "MPbut_plot_button_control(): "+SolutionFolder+":Waves4PMF"+"does not exists -> creating new wave"
		
		MPaux_Prompt4Wavesnames(solutionFolder,Wavenames,ctrlStruct.ctrlName,0)
		Wave/T Wavenames_temp=$(solutionFolder+":Wavenames_temp")
		
		MPaux_makeWaves4PMF(solutionFolder,Wavenames_temp)
		Killwaves/Z wavenames_temp
		
		// set Waves4PMF again
		Wave/T/Z Waves4PMF=$(SolutionFolder+":Waves4PMF")
		//Note Waves4PMF, "Names of Waves used for PMF  calcaulations in folder\r"+ FolderPath

	ENDIF

	//---------------------------------
	// select button procedure
	String Graphname=""
	String XwaveStr=""
	String factorList_Str=""
	Variable TimeStampTest
	Variable ii
	
	STRSWITCH(ctrlStruct.ctrlName)	// string switch
		
		// plot simple thermogram time series
		CASE "but_plotTseries":
			// check for Tdesorp wave (only wave needed for plots)
//			IF (!Waveexists($(solutionFolder+":"+Waves4PMF[%Tname])))
//				abortStr ="MPbut_plot_button_control():\r\rwave "+ SolutionFolder+":Waves4PMF not found"
//				MPaux_abort(AbortStr)
//			ENDIF

			MPplot_plotPMFtseries(SolutionFolder,aNote[0],Waves4PMF,unitStr=unitStr)
					
			BREAK

		//-------------------------------
		// plot factor thermograms split by samples
				
		CASE "but_plotTseriesSplit":
			
			// check for expWave
			IF (!waveexists(Explist))
				abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rcannot find ExpList Wave:\r"+ExpList_Str
				abortStr+="\rcheck Wave name in FitPET Panel"	
				MPaux_abort(AbortStr)
			ENDIF
			
			IF(numpnts(Explist)<1)
				abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rExpList Wave has 0 points. Check Wave given in FiTPET:\r"+ExpList_Str
				MPaux_abort(AbortStr)
			ENDIF
			
			IF (plotThermo_singleS_VAR==0)
				// plot all samples
				MPplot_plotPMFtseriessplit(SolutionFolder,aNote[0],ExpList_str,PanelNumber=panelPerCol_VAR,unitStr=unitStr)
			ELSE
				// plot single sample
				Make/O/T/N=(1) root:app:selectedExp
				Wave/T selectedExp=root:app:selectedExp
				
				// check if number is valid
				IF (plotThermo_Snum_VAR<0)	// less than 0
					abortStr="MPbut_plot_button_control - but_plotTseries:\r\rchosen sample number ("+num2str(plotThermo_Snum_VAR)+") is < 1"
					MPaux_abort(AbortStr)
				ENDIF
				IF ((plotThermo_Snum_VAR+1)>numpnts(Explist))	// samples are counted from 0
					abortStr="MPbut_plot_button_control - but_plotTseries:\r\rChosen sample number ("+num2str(plotThermo_Snum_VAR)
					abortStr+=") is too larger. \rValue must be 0 - "+num2str(numpnts(explist)-1)+" for experiment:\r"+SolutionFolder
					
					MPaux_abort(AbortStr)
				ENDIF
				IF (floor(plotThermo_Snum_VAR)!=plotThermo_Snum_VAR)	// check that value is natural number
					abortStr="MPbut_plot_button_control - but_plotTseries:\r\rChosen sample number ("+num2str(plotThermo_Snum_VAR)+") must be a natural number"
					MPaux_abort(abortStr)
				ENDIF

				selectedExp=expList[plotTHERMO_Snum_VAR]
				
				MPplot_plotPMFtseriessplit(SolutionFolder,aNote[0],"root:app:selectedExp",single=plotTHERMO_Snum_VAR,unitStr=unitStr)
			
			ENDIF
			
			BREAK
		
		//-------------------------------	
		// plot factor mass spectra
		
		CASE "but_plotMS":
		
			IF (plotMS_singleF_VAR==0)
			// plot all factors
				MPplot_plotPMFms(SolutionFolder,aNote[0],Waves4PMF,panelNumber=panelPerCol_VAR)
			ELSE
				// plot only single factor
				Make/FREE/D/N=(1) selectedFactor=plotMS_Fnum_VAR
				
				// check if number is valid
				Wave FactorList=$(SolutionFOlder+":FactorList_all")
				findvalue/V=(plotMS_Fnum_VAR) factorlist
				
				IF (V_value==-1)	// not in list
					factorList_Str=""
					FOR (ii=0;ii<numpnts(factorList);ii+=1)
						factorList_Str+=num2Str(factorlist[ii])+";"
					ENDFOR
					
					abortStr="MPbut_plot_button_control - but_plotMS:\r\rchosen factor number ("+num2str(plotMS_Fnum_VAR)
					abortStr+=") not found in list of factors for this solution:"
					abortStr+="\r"+solutionFolder
					abortSTr+="\r"+factorList_str
					MPaux_abort(abortSTr)
				ENDIF
				
				
				MPplot_plotPMFms(SolutionFolder,aNote[0],Waves4PMF,panelNumber=panelPerCol_VAR,order=selectedFactor)
				
			ENDIF
			
			BREAK
		//-------------------------------	
		// plot factor mass spectra as bubble plot
		
		CASE "but_plotMSbubble":
			
			// get info for lower threshold
			NVAR minBubble=root:app:minbubble_VAR
			
			IF (plotMS_singleF_VAR==0)
			// plot all factors
				MPplot_plotPMFmsBubble(SolutionFolder,aNote[0],panelNumber=panelPerCol_VAR,threshold=minbubble)
			ELSE
				// plot only single factor
				Make/FREE/D/N=(1) selectedFactor=plotMS_Fnum_VAR

				// check if number is valid
				Wave FactorList=$(SolutionFOlder+":FactorList_all")
				findvalue/V=(plotMS_Fnum_VAR) factorlist
				
				IF (V_value==-1)	// not in list
					
					factorList_Str=""
					FOR (ii=0;ii<numpnts(factorList);ii+=1)
						factorList_Str+=num2Str(factorlist[ii])+";"
					ENDFOR
					
					abortStr="MPbut_plot_button_control - but_plotMS:\r\rchosen factor number ("+num2str(plotMS_Fnum_VAR)
					abortStr+=") not found in list of factors for this solution:"
					abortStr+="\r"+solutionFolder
					abortSTr+="\r"+factorList_str
					MPaux_abort(abortSTr)
				ENDIF
	
				MPplot_plotPMFmsBubble(SolutionFolder,aNote[0],panelNumber=panelPerCol_VAR,order=selectedFactor,threshold=minbubble)
				
			ENDIF

			BREAK
		//-------------------------------	
		// plot factor mass spectra as grid plot
		
		CASE "but_plotMSgrid":
			
			// get info for lower threshold
			NVAR minBubble=root:app:minbubble_VAR
			
			IF (plotMS_singleF_VAR==0)
			// plot all factors
				MPplot_plotPMFmsgrid(SolutionFolder,aNote[0],panelNumber=panelPerCol_VAR,threshold=minbubble)
			ELSE
				// plot only single factor
				Make/FREE/D/N=(1) selectedFactor=plotMS_Fnum_VAR
				// check if number is valid
				Wave FactorList=$(SolutionFOlder+":FactorList_all")
				findvalue/V=(plotMS_Fnum_VAR) factorlist
				
				IF (V_value==-1)	// not in list
					
					factorList_Str=""
					FOR (ii=0;ii<numpnts(factorList);ii+=1)
						factorList_Str+=num2Str(factorlist[ii])+";"
					ENDFOR
					
					abortStr="MPbut_plot_button_control - but_plotMS:\r\rchosen factor number ("+num2str(plotMS_Fnum_VAR)
					abortStr+=") not found in list of factors for this solution:"
					abortStr+="\r"+solutionFolder
					abortSTr+="\r"+factorList_str
					MPaux_abort(abortSTr)
				ENDIF

				MPplot_plotPMFmsgrid(SolutionFolder,aNote[0],panelNumber=panelPerCol_VAR,order=selectedFactor,threshold=minbubble)
			ENDIF
			
			BREAK
		//-------------------------------	
		// plot factor mass spectra as mass defect plot
		
		CASE "but_plotMSmassdefect":
			
			// get info for lower threshold
			NVAR minBubble=root:app:minbubble_VAR
			
			IF (plotMS_singleF_VAR==0)
			// plot all factors
				MPplot_plotPMFmassdefect(SolutionFolder,aNote[0],Waves4PMF,panelNumber=panelPerCol_VAR,threshold=minBubble)
			ELSE
				// plot only single factor
				Make/FREE/D/N=(1) selectedFactor=plotMS_Fnum_VAR
				// check if number is valid
				Wave FactorList=$(SolutionFOlder+":FactorList_all")
				findvalue/V=(plotMS_Fnum_VAR) factorlist
				
				IF (V_value==-1)	// not in list
					
					factorList_Str=""
					FOR (ii=0;ii<numpnts(factorList);ii+=1)
						factorList_Str+=num2Str(factorlist[ii])+";"
					ENDFOR
					
					abortStr="MPbut_plot_button_control - but_plotMS:\r\rchosen factor number ("+num2str(plotMS_Fnum_VAR)
					abortStr+=") not found in list of factors for this solution:"
					abortStr+="\r"+solutionFolder
					abortSTr+="\r"+factorList_str
					MPaux_abort(abortSTr)
				ENDIF
				
				MPplot_plotPMFmassdefect(SolutionFolder,aNote[0],Waves4PMF,panelNumber=panelPerCol_VAR,order=selectedFactor,threshold=minBubble)
				
			ENDIF
		
			BREAK
				
		//-------------------------------	
		// plot VBS like
		CASE "but_plotVBS":
			
			// check for old folder
			IF (!datafolderExists(SolutionFolder+":FactorContrib_Tmax"))
				MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
			ENDIF
			
			// check for Explist wave
			IF (!waveexists(Explist))
				abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rcannot find ExpList Wave:\r"+ExpList_Str
				abortStr+="\rcheck Wave name in FitPET Panel"	
				MPaux_abort(AbortStr)
			ENDIF
			
			IF(numpnts(Explist)<1)
				abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rExpList Wave has 0 points. Check Wave given in FiTPET:\r"+ExpList_Str
				MPaux_abort(AbortStr)
			ENDIF

			// get Waves
			Wave FactorVBS=$(SolutionFolder+":FactorContrib_Tmax:FactorContrib_rel") 	// 2D wave: row: Factor column: Experiment
			Wave FactorList=$(SolutionFolder+":FactorList_all") 	// list with factor numbers to be plotted
			Wave TmaxInv=$(SolutionFolder+":FactorContrib_Tmax:TmaxI_split")	// 2D wave: TMax^-1 and errors 
			Wave TmaxErr=$(SolutionFolder+":FactorContrib_Tmax:TmaxIerr_split")
			
			MPplot_plotPMFVBS(SolutionFolder+":FactorContrib_Tmax",ExpList_str,FactorVBS,FactorList,TmaxInv,TmaxErr,panelNumber=panelPerCol_VAR)
			
			BREAK
			
		//-------------------------------	
		// bar plot of factor contributions
		
		CASE "but_plotbars":
		
			// check for old folder
			IF (!datafolderExists(SolutionFolder+":FactorContrib_Tmax"))
				MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
			ENDIF
			
			// get info about plotting type
			// absolute vs relative
			String	 Ytype="FactorContrib_abs"
			graphname=MPplot_MakeGraphName("FactorContrib_abs_",StringfromLIst(Itemsinlist(SolutionFolder,":")-1,SolutionFolder,":"),"")
			
			IF (plotBars_type_VAR==1)
				Ytype="FactorContrib_rel"
				graphname=MPplot_MakeGraphName("FactorContrib_Rel_",StringfromLIst(Itemsinlist(SolutionFolder,":")-1,SolutionFolder,":"),"")
			ENDIF
		
			// category vs time stamp
			XWaveStr=SolutionFolder+":Catlabel"
			IF(plotBars_Xtype_VAR==1)
				XwaveStr=SolutionFolder+":FactorContrib_Tmax:TimeStamp"
				
				// check for time stamp wave
				FigTimeName=""
				IF(FindDimLabel(Waves4PMF,0,"figtimename")!=-2)
					FigTimename=Waves4PMF[%FigTimeName]
				ENDIF	
				TimeStampTest=MPaux_check4TimeStamp(SolutionFolder,"TimeStamp",FigTimeName)
				
				IF (TimeStampTest==0)
					MPaux_abort(AbortStr)
				ENDIF
				
			ENDIF

			// get Waves
			Wave FactorVBS=$(SolutionFolder+":FactorContrib_Tmax:"+ytype) 	// 2D wave: row: sample, column: factor
			Wave FactorList=$(SolutionFolder+":FactorList_all") 	// list with factor numbers to be plotted
			Wave/T catLabel=$(SolutionFolder+":Catlabel")
			
			// check Catlabel Wave if that was selected
			IF (plotBars_Xtype_VAR==0)
				
				// check for ExpList Wave
				IF (!waveexists(Explist))
					abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rcannot find ExpList Wave:\r"+ExpList_Str
					abortStr+="\rcheck Wave name in FitPET Panel"	
					MPaux_abort(AbortStr)
				ENDIF
				
				IF(numpnts(Explist)<1)
					abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rExpList Wave has 0 points. Check Wave given in FiTPET:\r"+ExpList_Str
					MPaux_abort(AbortStr)
				ENDIF

				IF (!Waveexists(Catlabel) || numpnts(catlabel)!=numpnts(expList))
					Make/O/T/N=(numpnts(ExpList)) $(SolutionFolder+":Catlabel")
					Wave/T catLabel=$(SolutionFolder+":Catlabel")
					CatLabel=ExpList[p]
					print "-----------------"	
					print date()+" "+ time() + "\tplotting factor contributions vs category labels "
					IF (numpnts(catlabel)!=numpnts(expList))
						print "number of points in Catlabel wave ("+SolutionFolder+":Catlabel) not match Explist ("+ExpList_Str+")"
					ELSE
						print "Catlabel wave ("+SolutionFolder+":Catlabel) does not exist"
					ENDIF
					print "using ExpList as Labels"
				ENDIF
			ENDIF
			
			MPplot_plotPMFFactorContrib(SolutionFolder,FactorVBS,FactorList,XWaveStr,Graphname=Graphname)
		
			BREAK
		
		//-------------------------------	
		// bar plot of factor contributions
		
		CASE "but_plotTmax":
			NVAR PanelPerCol_VAR=root:APP:PanelPerCol_VAR
			NVAR TmaxType_VAR=root:APP:TmaxType_VAR
			
			// check for old folder
			IF (!datafolderExists(SolutionFolder+":FactorContrib_Tmax"))
				MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
			ENDIF
			
			// get info about plotting type
			Graphname="FactorTmax_"+StringfromList(Itemsinlist(SolutionFolder,":")-1,SolutionFolder,":")
			
			// category vs time stamp
			XWaveStr=SolutionFolder+":Catlabel"
			IF(plotBars_Xtype_VAR==1)
				XwaveStr=SolutionFolder+":FactorContrib_Tmax:TimeStamp"
				
				// check for time stamp wave
				FigTimeName=""
				IF(FindDimLabel(Waves4PMF,0,"figtimename")!=-2)
					FigTimename=Waves4PMF[%FigTimeName]
				ENDIF	
				TimeStampTest=MPaux_check4TimeStamp(SolutionFolder,"TimeStamp",FigTimeName)
				
				IF (TimeStampTest==0)
					MPaux_abort(AbortStr)
				ENDIF
				
			ENDIF
			
			// select Tmax or Median
			String TmaxName="FactorTmax"
			IF (TmaxType_VAR)
				TmaxName="FactorTmedian"
			ENDIF
			
			// get Waves
			Wave FactorTmax=$(SolutionFolder+":FactorContrib_Tmax:"+TmaxName) 	// 2D wave: row: sample, column: factor
			Wave FactorTmaxErr=$(SolutionFolder+":FactorContrib_Tmax:"+TmaxName+"Err") 	// 2D wave: row: sample, column: factor
			Wave FactorList=$(SolutionFolder+":FactorList_all") 	// list with factor numbers to be plotted
			Wave/T catLabel=$(SolutionFolder+":Catlabel")
			
			// catch if Tmedian does not exist (for older versions)
			IF (!waveexists(FactorTmax))
				abortSTr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rNo wave found with name:"
				abortStr+="\r"+SolutionFolder+":FactorContrib_Tmax:"+TmaxName
				
				// print info to History			
				print "-----------------"
				print date() + " " +time() +"\tplotting Tmax/Tmedian values vs sample names"	
				print "Wave not found: "
				print SolutionFolder+":FactorContrib_Tmax:"+TmaxName
				IF (stringmatch(TmaxName,"FactorTmedian"))
					print "'Tdemian' was chosen in the MaS-PET Panel. MaS-PET <2.03 did not calcaulate Tmedian."
					print "Choose Tmax instead or re-export the PMF solution"
				ENDIF				
				MPaux_abort(abortStr)
			
			ENDIF
			
			// check Catlabel Wave if that was selected
			IF (plotBars_Xtype_VAR==0)
				
				// check for ExpList Wave
				IF (!waveexists(Explist))
					abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rcannot find ExpList Wave:\r"+ExpList_Str
					abortStr+="\rcheck Wave name in FitPET Panel"	
					MPaux_abort(AbortStr)
				ENDIF
				
				IF(numpnts(Explist)<1)
					abortStr="MPbut_plot_button_control - "+ctrlStruct.ctrlName+":\r\rExpList Wave has 0 points. Check Wave given in FiTPET:\r"+ExpList_Str
					MPaux_abort(AbortStr)
				ENDIF

				IF (!Waveexists(Catlabel) || numpnts(catlabel)!=numpnts(expList))
					Make/O/T/N=(numpnts(ExpList)) $(SolutionFolder+":Catlabel")
					Wave/T catLabel=$(SolutionFolder+":Catlabel")
					CatLabel=ExpList[p]
					print "-----------------"
					print date() + " " +time() +"\tplotting Tmax/Tmedian values vs sample names"	
					print "Catlabel wave ("+SolutionFolder+":Catlabel) does not exist or does not match Explist ("+ExpList_Str+")"
					print "using ExpList as Labels instead"
				ENDIF
			ENDIF
						
			MPplot_plotPMFTmax(SolutionFolder,FactorTmax,FactorTmaxErr,FactorList,XWaveStr,Graphname=Graphname,panelnumber=PanelPerCol_VAR)
		
			BREAK
		
		//-------------------------------	
		
		// calculate diurnal trends for factor contributions
		CASE "but_calcDiel":
			NVAR PanelPerCol_VAR=root:APP:PanelPerCol_VAR
			NVAR GridHour_VAR=root:APP:GridHour_VAR
			NVAR minDiel_VAR=root:APP:minDiel_VAR
			
			// check MS type anbd create :FactorContrib_Tmax:FactorContrib_abs and timestamp wave
			Wave/T/Z PMFsolInfo=$(SolutionFolder+":PMFsolInfo")
			Wave/Z idxSample=$(SOlutionFolder+":idxSample")	// note this is a static name
			
			Variable MStype=str2num(PMFsolinfo[%data_type])	// get MStype
			
			IF (MStype!=2)	// if data is not FIGAERO TD
				// create copy of data using full time series
				String alertStr="MPbut_plot_button_control - but_calcDiel:\r\rUser selected to plot scaled diels for non-FIGAERO-TD data.\r"
				alertStr+=num2str(dimsize(idxSample,0))+" sample(s) detected.\r"
				alertStr+="Use full data set? (YES) or values by sample (NO)?"
				DoAlert/T="calculate Scaled Diels" 2,alertStr
				
				//cancel -> abort
				IF (V_flag==3)
					abort				
				ENDIF
				
				Variable ff,ss
				Wave tseries=$(Solutionfolder+":"+Waves4PMF[%Tname])	// time data
				
				//YES: use full data set as is
				IF (V_flag==1)
					Newdatafolder/O/S $(SolutionFolder+":FactorContrib_Tmax")
					
					// time wave
					Make/O/D/N=(numpnts(tseries)) TimeStamp=NaN
					TimeStamp=tseries
					SetScale d,0,0,"dat" ,TimeStamp
										
					// loop through factors
					Make/D/O/N=(numpnts(tseries),anote[0]) FactorContrib_abs=NaN
					
					FOR(ff=0;ff<(anote[0]);ff+=1)
						Wave CurrentFactorTS=$("::Factor_TS"+num2Str(ff+1))
						FactorContrib_abs[][ff]=CurrentFactorTS[p]					
					ENDFOR
				ENDIF
				
				// NO: use samples (not sure if this can happen with this version)
				IF (V_flag==2)
					// get values from dataSOrtedBysample folder
					setdatafolder $(SolutionFolder+":dataSortedBySample") // need to set current datafolder for Wavelist in Igor 7
					String listOfWave=WaveList("*_Farea",";","")
					
					Variable nos=Itemsinlist(listOfWave)
					Make/D/O/N=(nos,anote[0]) FactorContrib_abs=NaN	// rows: samples, columns factors
					make/D/O/N=(nos) TimeStamp=NaN
					SetScale d,0,0,"dat" ,TimeStamp
					
					FOR(ss=0;ss<(nos);ss+=1)
						// get factor Tseries
						Wave CurrentFactorTS=$("::dataSortedBySample:"+Stringfromlist(ss,listOfWave))
						FactorContrib_abs[ss][]=CurrentFactorTS[q]	[0]				
						// get timestamp
						TimeStamp[ss]=tseries[idxSample[ss][0]]
					ENDFOR				
				ENDIF
				
				// set no minimum value
				//minValue=0
			ENDIF

			
			// check for old folder
			IF (!datafolderExists(SolutionFolder+":FactorContrib_Tmax"))
				MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
			ENDIF
			
			// check for FigTimeseries
			FigTimeName=""
			IF(FindDimLabel(Waves4PMF,0,"figtimename")!=-2)
				FigTimename=Waves4PMF[%FigTimeName]
			ENDIF
			TimeStampTest=MPaux_check4TimeStamp(SolutionFolder,"TimeStamp",FigTimeName)

			IF (TimeStampTest==0)
				MPaux_abort(abortStr)
			ENDIF

			// do calculations	
			
			MPpost_CalcfactorDiurnals(SolutionFolder,"TimeStamp",GridHour_VAR,minDiel_VAR, 0)
			MPplot_plotAvgDiel(SolutionFolder,PanelPerCol_VAR,1)
			
			BREAK
		
		// caclulate and plot average thermograms
		CASE "but_calcAvgThermo":
			NVAR PanelPerCol_VAR=root:APP:PanelPerCol_VAR
			NVAR GridTdesorp_VAR=root:APP:GridTdesorp_VAR
					
			// check for old folder
			IF (!datafolderExists(SolutionFolder+":FactorContrib_Tmax"))
				MPpost_convertVBS_allFolder(SolutionFolder,"VBS_all")
			ENDIF
			
			// check if Explist4PMF was saved in folder -> copy current Explist from Panel
			IF (!Waveexists($Explist4PMF_str))
				Make/T/O/N=(numpnts(Explist)) $(SolutionFolder+":ExpList4PMF")
				Wave/T Explist4PMF=$(SolutionFolder+":ExpList4PMF")
				Explist4PMF=Explist
			ENDIF
			
			MPpost_CalcAvgFactorThermo(SolutionFolder,0.01,GridTdesorp_VAR,0,Waves4PMF[%Tname],ExpList4pmf_Str)
			MPplot_plotAvgDiel(SolutionFolder,PanelPerCol_VAR,2)
			
			BREAK
		
		DEFAULT:			// optional default expression executed
			Setdatafolder $oldFolder
			abortStr="plot_button_control\r\runable to identify button type\rCheck code in:\r\r'plot_button_control'"
			MPaux_abort(AbortStr)
			
	ENDSWITCH

	Setdatafolder $oldFolder

ENDIF


END

//======================================================================================
//======================================================================================

//======================================================================================
//		check box buttons
//======================================================================================

//======================================================================================

// Purpose:		toggle linear/log of y axis in PL error panel
// Input:			ctrlStruct
// Output:		axis gets adjusted
// called by:	checkbox in PLerror Panel

FUNCTION MPbut_cb_log_func(ctrlStruct)	: checkboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF(ctrlStruct.eventCode==2)	// mouse release
	
	// selected -> set to log
	modifygraph/W=PLerror_panel#Sij_plot log=(ctrlStruct.checked)
	
ENDIF

END

//======================================================================================
//======================================================================================

//======================================================================================
//		other buttons like functions
//======================================================================================

//======================================================================================

// Purpose:	check if the set solution or data folder exists and set check light to red/green
// Input:		Ctrl struct of the folder string field
// 				
// Output :	sets box next to folder name field to green/red

FUNCTION MPbut_Checklight4Folder(ctrlStruct)

STRUCT WMSetVariableAction &ctrlStruct


// only activate if field lost focus
IF (ctrlStruct.eventCode==8)	//8: end edit
	// red colour
	Variable red=65535
	Variable green=0
	Variable blue=0
	
	Variable ypos=CtrlStruct.ctrlrect.top
	Variable xpos=CtrlStruct.ctrlrect.right+1
	
	// check if folder exists
	IF (Datafolderexists(ctrlStruct.sval))
		// switch to green
		red=0
		green=65535
		blue=0
		
		// lower position
		ypos+=9
	ENDIF
	
	// set colour
	String gpName= "GB_"+ctrlstruct.ctrlname
	groupBox $gpName win=MASPET_PANEL, labelBack=(red,green,blue),pos={xpos,ypos},size={12,9}
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	check if a valid number was used in the panels per column field
// Input:		Ctrl struct of the folder string field
// 				
// Output :	changes to the neares integer

FUNCTION MPbut_checkPerColVal(ctrlStruct)

STRUCT WMSetVariableAction &ctrlStruct

IF (ctrlStruct.eventCode==8)
	// check if value is a positive integer
	NVAR panelPerCol=root:app:panelPerCol_var
	
	Variable value=ctrlStruct.dval
	IF (value!=round(value))
		panelPerCol=round(value)
		// inform user in history window
		print "-----------------"
		print "user selected a illegal value for 'panels per column': "+num2str(value)
		print "rounded to nearest legal integer value: "+num2str(panelPerCol)
	ENDIF
	
ENDIF

END

//======================================================================================
//======================================================================================
// control chechbox behaviour for prep data part

FUNCTION MPbut_master_checkbox_control(ctrlStruct)	: CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// wave holding checkbox values
	Wave cbValues_prepData=root:APP:cbValues_prepData
	
	String cbName=ctrlStruct.ctrlname
	String labelName=replaceString("cb_",cbname,"")

	cbValues_prepData[%$labelname]=ctrlStruct.checked

	//-----------------------------
	// handle CN error type checkbox
	IF (Stringmatch(cbName,"cb_calcErrors"))
		// set radio buttons to active/inactive
		Variable checked=0
		IF (ctrlStruct.checked==0)
			checked=2
		ENDIF		
		checkbox radio_CNtype_end, disable=checked,win=MASPET_PANEL
		checkbox radio_CNtype_all, disable=checked,win=MASPET_PANEL
		checkbox radio_CNtype_avg, disable=checked,win=MASPET_PANEL
		checkbox cb_SaveErrHisto, disable=checked,win=MASPET_PANEL
	ENDIF

	//-----------------------------
	// handle old ACSM checkbox
	NVAR MStype_VAR=root:app:MStype_VAR
	NVAR dataTypeHR_VAR=root:app:datatypeHR_VAR
	
	IF (Stringmatch(cbName,"cb_oldACSM"))
		// set MStype
		MSType_VAR = 6+1*ctrlStruct.checked	// if checked -> 6, if unchecked -> 5
		// uncheck Q-AMS if oldACSM is selected
		IF (ctrlStruct.checked	)
			cbValues_prepData[%quadAMS]=0
			checkbox cb_quadAMS, value=cbValues_prepData[%quadAMS],win=MASPET_PANEL
		ENDIF
	ENDIF
	
	// handle quadAMS checkbox
	IF (Stringmatch(cbName,"cb_quadAMS"))
		// set MStype
		MSType_VAR = 6+2*ctrlStruct.checked	// if checked -> 7, if unchecked -> 5
		// uncheck old ACSm if Q-AMS is selected
		IF (ctrlStruct.checked	)
			cbValues_prepData[%oldACSM]=0
			checkbox cb_oldACSM, value=cbValues_prepData[%oldACSM],win=MASPET_PANEL
		ENDIF		
	ENDIF
	
	//-----------------------------
	// handle element ratio checkbox
	IF (Stringmatch(cbName,"cb_ElementRatio"))
		MSType_VAR = 4+ctrlStruct.checked	// 3 normal AMS HR, 4: with elemental ratios
		IF (ctrlStruct.checked)
			//checked -> with element ratio =1
			datatypeHR_VAR=1
		ELSE
			//only family coloured =2
			datatypeHR_VAR=2
		ENDIF
	ENDIF
	
	// capture vaporiser selected
	IF (Stringmatch(cbName,"cb_capVap"))
		NVAR capvapFlag_VAR=root:APP:capvapFlag_VAR
		capvapFlag_VAR=ctrlStruct.checked
	ENDIF		

	// adjust visible items if MStype_var has changed
	NVAR activeTab_VAR=root:APP:activeTab_VAR	// which tab is active
	MPmain_setControls(activeTab_VAR,MStype_VAR)

ENDIF

END

//======================================================================================
//======================================================================================

//======================================================================================
//		radio buttons
//======================================================================================

//===================================
// top layer for controlling radio button behaviour for selecting MS type
// this sets which controls to show/hide

FUNCTION MPbut_radio_MSType_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	//do the actual stuff
	MPbut_radio_MSType_action(ctrlStruct.ctrlname)
	
ENDIF

END

//======================================================================================
//======================================================================================

// controlling radio button behaviour for selecting MS type
// can be called for real button click or from function

FUNCTION MPbut_radio_MSType_action(Ctrlname)

String Ctrlname	// name of radio button

Wave radioValues_MSType=root:app:radioValues_MSType
NVAR MStype_VAR=root:APP:MStype_VAR	// for data type (0: gas HR, 1: gas UMR, 2: Figaero thermo, 3: FIGAERO MSint, 4: aero HR, 5: aero HR with elemet, 6:aero UMR, 7: old ACSM, 8: old Q-AMS)
NVAR dataTypeHR_VAR=root:APP:dataTypeHR_VAR	// for PET Results (0: UMR and other HR, 1: HRAMS,2: HR AMS with family colours)
NVAR capVapFlag_VAR=root:app:capvapflag_VAR	// setting of vapture vaporiser
NVAR activeTab_VAR=root:APP:activeTab_VAR	// which tab is active

Variable oldACSM_VAR, quadAMS_VAR

// set to new selected MS type	
STRSWITCH (ctrlname)			

	// gas phase data
	CASE "radio_MSType_Gas_MS":
		// set radio values
		radioValues_MSType[%Gas_MS]=1
		radioValues_MSType[%FIGAERO]=0
		radioValues_MSType[%aero_MS]=0
		
		// activate HR/UMR radio buttons
		checkbox radio_MSType_gas_MS_HR disable=0
		checkbox radio_MSType_gas_MS_UMR disable=0
		checkbox radio_MSType_aero_MS_HR disable=2
		checkbox radio_MSType_aero_MS_UMR disable=2
		checkbox radio_MSType_FIGAERO_TD disable=2
		checkbox radio_MSType_FIGAERO_MSint disable=2
		
		// store types in VAR	
		Controlinfo 	radio_MSType_gas_MS_HR
		IF (V_value==1)		
			MStype_VAR=0	// gas HR
		ELSE
			MStype_VAR=1	// gas UMR
		ENDIF
		
		dataTypeHR_VAR=0

		//adjust label
		TitleBox Title_label0_9, title="time series"
		TitleBox Title_label0_10, disable=1
		SetVariable VarTxt_FigTimeName_pmf disable=1
		
		BREAK

	// FIGAERO thermogram
	CASE "radio_MSType_FIGAERO":
		// set radio values
		radioValues_MSType[%Gas_MS]=0
		radioValues_MSType[%FIGAERO]=1
		radioValues_MSType[%aero_MS]=0
		
		// activate TD/integrated radio buttons
		checkbox radio_MSType_gas_MS_HR disable=2
		checkbox radio_MSType_gas_MS_UMR disable=2
		checkbox radio_MSType_aero_MS_HR disable=2
		checkbox radio_MSType_aero_MS_UMR disable=2
		checkbox radio_MSType_FIGAERO_TD disable=0
		checkbox radio_MSType_FIGAERO_MSint disable=0
								
		// store types in VAR
		MStype_VAR=2
		dataTypeHR_VAR=0
		
		Controlinfo radio_MSType_FIGAERO_MSint
		IF (V_Value==1)	// integrated
			MStype_VAR=3

			//adjust label
			TitleBox Title_label0_9, title="time series"
			TitleBox Title_label0_10, disable=1
			SetVariable VarTxt_FigTimeName_pmf disable=1
		
		ELSE	// TD
			//adjust label
			TitleBox Title_label0_9, title="T desorp"
			TitleBox Title_label0_10, disable=0
			SetVariable VarTxt_FigTimeName_pmf disable=0
			
		ENDIF
		
		BREAK
		
	// particle phase daa
	CASE "radio_MSType_aero_MS":
		
		// set radio values
		radioValues_MSType[%Gas_MS]=0
		radioValues_MSType[%FIGAERO]=0
		radioValues_MSType[%aero_MS]=1
		
		// activate HR/UMR radio buttons
		checkbox radio_MSType_gas_MS_HR disable=2
		checkbox radio_MSType_gas_MS_UMR disable=2
		checkbox radio_MSType_aero_MS_HR disable=0
		checkbox radio_MSType_aero_MS_UMR disable=0
		checkbox radio_MSType_FIGAERO_TD disable=2
		checkbox radio_MSType_FIGAERO_MSint disable=2
					
		// store types in VAR
					
		dataTypeHR_VAR=0
		
		Controlinfo radio_MSType_aero_MS_HR
		IF (V_value==1)
			// HR selected
			ControlInfo cb_ElementRatio
			IF (V_value==1)
				MStype_VAR=5	// do elemental ratios
				dataTypeHR_VAR=1
			ELSE
				MStype_VAR=4	// only family color coding
				dataTypeHR_VAR=2
			ENDIF
			
		ELSE
			// UMR selected
			ControlInfo cb_oldACSM
			oldACSM_VAR=v_value
			ControlInfo cb_quadAMS
			quadAMS_VAR=V_value
			
			IF (quadAMS_VAR==1 && oldACSM_VAR==1)	// catch user messing up
				doalert 0,"Both old ACSM and Q-AMS selected. Please pick only one."
			ENDIF
			
			MStype_VAR=6
			
			IF (oldACSM_VAR==1)
				MStype_VAR=7	// Q-ACSM
			ENDIF
			IF (quadAMS_VAR==1)
				MStype_VAR=8	// old Q-AMS
			ENDIF	
		
		ENDIF
		
		//adjust label
		TitleBox Title_label0_9, title="time series"
		TitleBox Title_label0_10, disable=1
		SetVariable VarTxt_FigTimeName_pmf disable=1
		
		BREAK
	
//-----------------------------
	// gas phase HR
	CASE "radio_MSType_gas_MS_HR":
		radioValues_MSType[%Gas_MS_HR]=1
		radioValues_MSType[%Gas_MS_UMR]=0

		// store types in VAR
		MStype_VAR=0
		dataTypeHR_VAR=0
	
		BREAK
	// gas phase UMR
	CASE "radio_MSType_gas_MS_UMR":
		radioValues_MSType[%Gas_MS_HR]=0
		radioValues_MSType[%Gas_MS_UMR]=1

		// store types in VAR
		MStype_VAR=1
		dataTypeHR_VAR=0
	
		BREAK

//-----------------------------			
	// FIGAERO thermogram
	CASE "radio_MSType_FIGAERO_TD":
		// set radio values
		radioValues_MSType[%FIGAERO_TD]=1
		radioValues_MSType[%FIGAERO_msint]=0			
								
		// store types in VAR
		MStype_VAR=2
		dataTypeHR_VAR=0

		//adjust label
		TitleBox Title_label0_9, title="T desorp"
		TitleBox Title_label0_10, disable=0
		SetVariable VarTxt_FigTimeName_pmf disable=0
		
		BREAK
		
	// FIGAERO thermogram
	CASE "radio_MSType_FIGAERO_msint":
		// set radio values
		radioValues_MSType[%FIGAERO_TD]=0
		radioValues_MSType[%FIGAERO_msint]=1
											
		// store types in VAR
		MStype_VAR=3
		dataTypeHR_VAR=0

		//adjust label
		TitleBox Title_label0_9, title="time series"
		TitleBox Title_label0_10, disable=1
		SetVariable VarTxt_FigTimeName_pmf disable=1
		
		BREAK
		
//-----------------------------
	// aerosol phase stuff					
	// HR (AMS and ACSM-X)
	CASE "radio_MSType_aero_MS_HR":
		//set radio values
		radioValues_MSType[%aero_MS_HR]=1
		radioValues_MSType[%aero_MS_UMR]=0
	
		// store types in VAR			
		ControlInfo cb_ElementRatio
		IF (V_value==1)
			MStype_VAR=5	// do elemental ratios
			dataTypeHR_VAR=1
		ELSE
			MStype_VAR=4	// only family color coding
			dataTypeHR_VAR=2
		ENDIF

		//adjust label
		TitleBox Title_label0_9, title="time series"
		TitleBox Title_label0_10, disable=1
		SetVariable VarTxt_FigTimeName_pmf disable=1
		
		BREAK

	// UMR (=ACSM and Quad-AMS)
	CASE "radio_MSType_aero_MS_UMR":
		//set radio values
		radioValues_MSType[%aero_MS_HR]=0
		radioValues_MSType[%aero_MS_UMR]=1
	
		// store types in VAR			
		ControlInfo cb_oldACSM
		oldACSM_VAR=v_value
		ControlInfo cb_quadAMS
		quadAMS_VAR=V_value
		
		IF (quadAMS_VAR==1 && oldACSM_VAR==1)	// catch user messing up
			doalert 0,"Both old ACSm and Q-AMS selected. Please pick only one."
		ENDIF
		
		MStype_VAR=6
		
		IF (quadAMS_VAR==1)
			MStype_VAR=8	// old quad AMS
		ENDIF
		IF (oldACSM_VAR==1)
			MStype_VAR=7	// Q-ACSM
		ENDIF
		dataTypeHR_VAR=0
		
		//adjust label
		TitleBox Title_label0_9, title="time series"
		TitleBox Title_label0_10, disable=1
		SetVariable VarTxt_FigTimeName_pmf disable=1
		
		BREAK

	DEFAULT:
		print "MPbut_radio_MSType_control(): problem with strswitch"
		BREAK
		
ENDSWITCH

// update radio button appearance
String ControlIDs="Gas_MS;Gas_MS_HR;Gas_MS_UMR;FIGAERO;FIGAERO_TD;FIGAERO_msint;aero_MS;aero_MS_HR;aero_MS_UMR;"
Variable ii
FOR (ii=0;ii<Itemsinlist(ControlIDs);ii+=1)
	String CurrentControlName="radio_MSType_"+Stringfromlist(ii,ControlIDs)
	String LabelName=Stringfromlist(ii,ControlIDs)
	
	Checkbox $CurrentControlName, value=radioValues_MSType[%$Labelname]
ENDFOR

// set AMS related stuff
IF(MStype_VAR==4 || MStype_VAR==5)
	// AMS HR
	Checkbox cb_capVap, disable=0,win=MaSPET_Panel
	Checkbox cb_ElementRatio,disable=0,win=MaSPET_Panel
ELSE
	// not AMS -> disable AMS stuff
	Checkbox cb_capVap, disable=2,win=MaSPET_Panel
	Checkbox cb_ElementRatio,disable=2,win=MaSPET_Panel
ENDIF

// set Aerosol UMR related stuff
IF(MStype_VAR==6 || MStype_VAR==7 || MStype_VAR ==8)
	// aerosol UMR
	Checkbox cb_oldACSM, disable=0,win=MaSPET_Panel
	Checkbox cb_quadAMS,disable=0,win=MaSPET_Panel
ELSE
	// other -> disable aerosol UMR
	Checkbox cb_oldACSM, disable=2,win=MaSPET_Panel
	Checkbox cb_quadAMS,disable=2,win=MaSPET_Panel
ENDIF

// hide controls
NVAR activeTab_VAR=root:APP:activeTab_VAR	// which tab is active

MPmain_setControls(activeTab_VAR,msType_VAR)
	
END

//======================================================================================
//======================================================================================
// top layer for controlling radio button behaviour for load data function
// this sets which controls to show/hide

FUNCTION MPbut_radio_DL_loadType_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	
	MPbut_radio_DL_loadType_action(ctrlStruct.ctrlname)

ENDIF

END

//======================================================================================
//======================================================================================
// controlling radio button behaviour for load data function
// can be called for real button click or from function

FUNCTION MPbut_radio_DL_loadType_action(Ctrlname)

String Ctrlname

Wave radioValues_loadType=root:app:dataLoader:radioValues_loadType

Wave/T FileExtensions=root:APP:dataloader:FileExtensions

NVAR loadSampleType_VAR=root:APP:dataLoader:loadSampleType_VAR
NVAR loadDelimType_VAR=root:APP:dataLoader:loadDelimType_VAR
NVAR loadfileType_VAR=root:APP:dataLoader:loadfileType_VAR
NVAR timeFormat_VAR=root:APP:dataLoader:timeFormat_VAR

SVAR loadFileType_STR=root:APP:dataLoader:loadFileType_STR
SVAR FileLabelList=root:APP:dataLoader:FileLabelList
SVAR FileExtensions_STR=root:app:dataloader:FileExtensions_STR

Variable ii
		
STRSWITCH (ctrlname)
	
	// file type
	
	// ibw clicked
	CASE "radio_loadType_ibw":
		radioValues_loadType[%ibw]=1
		radioValues_loadType[%itx]=0
		radioValues_loadType[%txt]=0
		
		loadFileType_VAR=0
		loadFileType_STR="ibw"
		FileExtensions="ibw"
		FileExtensions[8]="itx"	// AMS multi wave itx
		
		// deactivate delimiter radios
		Checkbox radio_loadType_comma,disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_semicolon,disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_tab,disable=1,win=DataLoader_Panel
		
		// deactivate time format stuff
		Checkbox radio_loadType_IgorSec, disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_MatlabSec,disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_TimeTXT,disable=1,win=DataLoader_Panel
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel

		// disable file extension edit
		FOR (ii=0;ii<Itemsinlist(FileLabelList)-1;ii+=1)
			SetVariable $("VarTxt_"+StringFromList(ii,FileLabelList)+"_ext") disable=2,noedit=0,win=DataLoader_Panel
		ENDFOR
		// default file extension
		SetVariable VARTXT_defaultExtension disable=2,noedit=0,win=Dataloader_Panel

		// time format str
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel

		BREAK
	
	// itx clicked
	CASE "radio_loadType_itx":
		radioValues_loadType[%ibw]=0
		radioValues_loadType[%itx]=1
		radioValues_loadType[%txt]=0
		
		loadFileType_VAR=1
		loadFileType_STR="itx"
		FileExtensions="itx"
				
		// deactivate delimiter radios
		Checkbox radio_loadType_comma disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_semicolon disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_tab disable=1,win=DataLoader_Panel
		
		// deactivate time format stuff
		Checkbox radio_loadType_IgorSec, disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_MatlabSec,disable=1,win=DataLoader_Panel
		Checkbox radio_loadType_TimeTXT,disable=1,win=DataLoader_Panel
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel

		// disable file extension edit
		FOR (ii=0;ii<Itemsinlist(FileLabelList)-1;ii+=1)
			SetVariable $("VarTxt_"+StringFromList(ii,FileLabelList)+"_ext") disable=2,noedit=0,win=DataLoader_Panel
		ENDFOR
		// default file extension
		SetVariable VARTXT_defaultExtension disable=2,noedit=0,win=Dataloader_Panel
		
		// time format str
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel

		BREAK
		
	// txt clicked
	CASE "radio_loadType_txt":
		radioValues_loadType[%ibw]=0
		radioValues_loadType[%itx]=0
		radioValues_loadType[%txt]=1
		
		loadFileType_VAR=2
		loadFileType_STR=FileExtensions_STR
		FileExtensions=FileExtensions_STR
		FileExtensions[8]="itx"	// AMS multi wave itx4
					
		FOR (ii=0;ii<Itemsinlist(FileLabelList)-1;ii+=1)
			SetVariable $("VarTxt_"+StringFromList(ii,FileLabelList)+"_ext") disable=0,noedit=0,win=DataLoader_Panel
		ENDFOR
		// default file extension
		SetVariable VARTXT_defaultExtension disable=0,noedit=0,win=Dataloader_Panel

		// activate delimiter radios
		Checkbox radio_loadType_comma,disable=0,win=DataLoader_Panel
		Checkbox radio_loadType_semicolon,disable=0,win=DataLoader_Panel
		Checkbox radio_loadType_tab,disable=0,win=DataLoader_Panel
		
		// enable time format stuff
		Checkbox radio_loadType_IgorSec, disable=0,win=DataLoader_Panel
		Checkbox radio_loadType_MatlabSec,disable=0,win=DataLoader_Panel
		Checkbox radio_loadType_TimeTXT,disable=0,win=DataLoader_Panel
		
		ControlInfo/w=DataLoader_Panel radio_loadType_TimeTXT
		IF (V_value==0)
			Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel
		ELSE
			Setvariable VarTxt_TimeFormat,disable=0,win=DataLoader_Panel
		ENDIF
		
		BREAK

	//----------------------
	// delimiter
	CASE "radio_loadType_comma":
		radioValues_loadType[%comma]=1
		radioValues_loadType[%semicolon]=0
		radioValues_loadType[%tab]=0
		
		loadDelimType_VAR=0
		BREAK
	
	CASE "radio_loadType_semicolon":
		radioValues_loadType[%comma]=0
		radioValues_loadType[%semicolon]=1
		radioValues_loadType[%tab]=0
		
		loadDelimType_VAR=1
		BREAK

	CASE "radio_loadType_tab":
		radioValues_loadType[%comma]=0
		radioValues_loadType[%semicolon]=0
		radioValues_loadType[%tab]=1
		
		loadDelimType_VAR=2
		BREAK
	
	//----------------------
	// data set type
	
	// multi clicked
	CASE "radio_loadType_multi":
		radioValues_loadType[%multi]=1
		radioValues_loadType[%single]=0
		radioValues_loadType[%other]=0
		
		loadSampleType_VAR=0
		BREAK
	
	// single clicked
	CASE "radio_loadType_single":
		radioValues_loadType[%multi]=0
		radioValues_loadType[%single]=1
		radioValues_loadType[%other]=0
		
		loadSampleType_VAR=1
		BREAK
		
	// other clicked
	CASE "radio_loadType_other":
		radioValues_loadType[%multi]=0
		radioValues_loadType[%single]=0
		radioValues_loadType[%other]=1
		
		loadSampleType_VAR=2
		BREAK
	
	//----------------------
	// time format for text file load
	
	// IgorSec
	CASE "radio_loadType_IgorSec":
		timeFormat_VAR=0
		
		radioValues_loadType[%IgorSec]=1
		radioValues_loadType[%MAtLabSec]=0
		radioValues_loadType[%TimeTXT]=0
		
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel
		BREAK
	
	// matlabSec
	CASE "radio_loadType_MatlabSec":
		timeFormat_VAR=1
		
		radioValues_loadType[%IgorSec]=0
		radioValues_loadType[%MAtLabSec]=1
		radioValues_loadType[%TimeTXT]=0
		
		Setvariable VarTxt_TimeFormat,disable=1,win=DataLoader_Panel
		BREAK
	
	// matlabSec
	CASE "radio_loadType_TimeTXT":
		timeFormat_VAR=2
		
		radioValues_loadType[%IgorSec]=0
		radioValues_loadType[%MAtLabSec]=0
		radioValues_loadType[%TimeTXT]=1
		
		Setvariable VarTxt_TimeFormat,disable=0,win=DataLoader_Panel
		BREAK
		
	//----------------------
	DEFAULT:
		print "MPbut_radio_DL_loadType_control: problem with strswitch"
		BREAK
	
ENDSWITCH

// upate radio button appearance
Checkbox radio_loadType_ibw, value=radioValues_loadType[%ibw],win=DataLoader_Panel
Checkbox radio_loadType_itx, value=radioValues_loadType[%itx],win=DataLoader_Panel
Checkbox radio_loadType_txt, value=radioValues_loadType[%txt],win=DataLoader_Panel

Checkbox radio_loadType_comma, value=radioValues_loadType[%comma],win=DataLoader_Panel
Checkbox radio_loadType_semicolon, value=radioValues_loadType[%semicolon],win=DataLoader_Panel
Checkbox radio_loadType_tab, value=radioValues_loadType[%tab],win=DataLoader_Panel

Checkbox radio_loadType_multi, value=radioValues_loadType[%multi],win=DataLoader_Panel
Checkbox radio_loadType_single, value=radioValues_loadType[%single],win=DataLoader_Panel
Checkbox radio_loadType_other, value=radioValues_loadType[%other],win=DataLoader_Panel

Checkbox radio_loadType_IgorSec, value=radioValues_loadType[%IgorSec],win=DataLoader_Panel
Checkbox radio_loadType_MatlabSec, value=radioValues_loadType[%MAtLabSec],win=DataLoader_Panel
Checkbox radio_loadType_TimeTXT, value=radioValues_loadType[%TimeTXT],win=DataLoader_Panel

END

//======================================================================================
//======================================================================================
// control radio button behaviour for setting type of CN error calculation

FUNCTION MPbut_radio_CNtype_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	Wave radioValues_CNType=root:app:radioValues_CNType
	NVAR CNtype_VAR=root:APP:CNtype_VAR
	
	STRSWITCH (ctrlStruct.ctrlname)
		// end clicked
		CASE "radio_CNtype_end":
			radioValues_CNType[0]=1
			radioValues_CNType[1]=0
			radioValues_CNType[2]=0
			
			CNtype_VAR=0
			
			BREAK
		// all clicked
		CASE "radio_CNtype_all":
			radioValues_CNType[0]=0
			radioValues_CNType[1]=1
			radioValues_CNType[2]=0
			
			CNtype_VAR=1
			BREAK

		// LT median clicked
		CASE "radio_CNtype_avg":
			radioValues_CNType[0]=0
			radioValues_CNType[1]=0
			radioValues_CNType[2]=1

			CNtype_VAR=2
			BREAK
		
		
		DEFAULT:
			print "MPbut_radio_removeIons_control: problem with strswitch"
			BREAK
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_CNtype_end, value=radioValues_CNType[0],win=MaSPET_Panel
	Checkbox radio_CNtype_all, value=radioValues_CNType[1],win=MaSPET_Panel
	Checkbox radio_CNtype_avg, value=radioValues_CNType[2],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================
// control radio button behaviour for remove ions

FUNCTION MPbut_radio_removeIons_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	Wave radioValues_removeIons=root:app:radioValues_removeIons
	
	STRSWITCH (ctrlStruct.ctrlname)
		// idx clicked
		CASE "radio_removeIons_IDX":
			radioValues_removeIons[0]=1
			radioValues_removeIons[1]=0
			
			SetVariable VarNUM_removeIons_idx, disable=0,win=MaSPET_Panel
			SetVariable Vartxt_removeIons_label, disable=2,win=MaSPET_Panel
			
			BREAK
		// label clicked
		CASE "radio_removeIons_label":
			radioValues_removeIons[0]=0
			radioValues_removeIons[1]=1
			
			SetVariable VarNUM_removeIons_idx, disable=2,win=MaSPET_Panel
			SetVariable Vartxt_removeIons_label, disable=0,win=MaSPET_Panel
			
			BREAK
		DEFAULT:
			print "MPbut_radio_removeIons_control: problem with strswitch"
			BREAK
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_removeIons_idx, value=radioValues_removeIons[0],win=MaSPET_Panel
	Checkbox radio_removeIons_label, value=radioValues_removeIons[1],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================
// control radio button behaviour for wave names (use of noNans prefix)

FUNCTION MPbut_radio_useNaNs_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// values for Radio buttons
	Wave radioValues_useNoNans=root:app:radioValues_useNoNans
	// wavenames
	Wave/T Wavenames=root:APP:datawaveNames
	
	STRSWITCH (ctrlStruct.ctrlname)
		// NO clicked
		CASE "radio_useNoNans_NO":
			radioValues_useNoNans[0]=1
			radioValues_useNoNans[1]=0
			
			// remove noNans from names
			WaveNames=replaceString("noNans_",WaveNames[p],"")
			
			BREAK
		// YES clicked
		CASE "radio_useNoNans_Yes":
			radioValues_useNoNans[0]=0
			radioValues_useNoNans[1]=1
			
			WaveNames="noNans_"+Wavenames[p]
			BREAK
		DEFAULT:
			print "MPbut_radio_useNaNs_control: problem with strswitch"
			BREAK

	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_useNoNans_NO, value=radioValues_useNoNans[0],win=MaSPET_Panel
	Checkbox radio_useNoNans_YES, value=radioValues_useNoNans[1],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================
// control radio button behaviour using fpeak or seed

FUNCTION MPbut_radio_fpeakSeed_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// values for Radio buttons
	Wave radioValues_fpeakSeed=root:app:radioValues_fpeakSeed
	NVAR seedOrFpeak_VAR=root:app:seedOrFpeak_Var
	
	STRSWITCH (ctrlStruct.ctrlname)
		// NO clicked
		CASE "radio_useFpeak":
			radioValues_fpeakSeed[0]=1
			radioValues_fpeakSeed[1]=0
			
			seedOrFpeak_VAR=0
			BREAK
		// YES clicked
		CASE "radio_useSeed":
			radioValues_fpeakSeed[0]=0
			radioValues_fpeakSeed[1]=1
			
			seedOrFpeak_VAR=1
			
			BREAK
		DEFAULT:
			print "MPbut_radio_fpeakSeed_control: problem with strswitch"
			BREAK
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_useFpeak, value=radioValues_fpeakSeed[0],win=MaSPET_Panel
	Checkbox radio_useSeed, value=radioValues_fpeakSeed[1],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================

// control radio button behaviour for export time format

FUNCTION MPbut_radio_Variance_Control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// values for radiobuttons
	Wave radioValues_VarianceType=root:app:radioValues_VarianceType

	// toggle switches as variables
	NVAR VarianceType_VAR=root:APP:VarianceType_VAR
		
	STRSWITCH (ctrlStruct.ctrlname)
		// absolute distance
		CASE "radio_Variance_abs":
			radioValues_VarianceType[0]=1
			radioValues_VarianceType[1]=0
			
			VarianceType_VAR=0
			BREAK
		// square distance
		CASE "radio_Variance_square":
			radioValues_VarianceType[0]=0
			radioValues_VarianceType[1]=1
			
			VarianceType_VAR=1
			BREAK
		DEFAULT:
			print "MPbut_radio_Variance_Control: problem with strswitch"
			BREAK
					
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_Variance_abs, value=radioValues_VarianceType[0],win=MaSPET_Panel
	Checkbox radio_Variance_square, value=radioValues_VarianceType[1],win=MaSPET_Panel

ENDIF



END

//======================================================================================
//======================================================================================
// control radio button behaviour for single/all factor plotting

FUNCTION MPbut_radio_plotMS_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
// values for radio button
	Wave radioValues_plotMS=root:app:radioValues_plotMS
	
	NVAR plotMS_singleF_VAR=root:APP:plotMS_singleF_VAR	//0/1 for all/single factor
	
	STRSWITCH (ctrlStruct.ctrlname)
		// all clicked
		CASE "radio_plotMS_allF":
			radioValues_plotMS[0]=1
			radioValues_plotMS[1]=0
			
			SetVariable VarNUM_plotMS_Fnum, disable=2,win=MaSPET_Panel
			plotMS_singleF_VAR=0
			
			BREAK
		// single clicked
		CASE "radio_plotMS_singleF":
			radioValues_plotMS[0]=0
			radioValues_plotMS[1]=1
			
			SetVariable VarNUM_plotMS_Fnum, disable=0,win=MaSPET_Panel
			plotMS_singleF_VAR=1
			BREAK
		DEFAULT:
			print "MPbut_radio_plotMS_control: problem with strswitch"
			BREAK

	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_plotMS_allF, value=radioValues_plotMS[0],win=MaSPET_Panel
	Checkbox radio_plotMS_singleF, value=radioValues_plotMS[1],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================
// control radio button behaviour for single/all thermogram plotting

FUNCTION MPbut_radio_plotthermo_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
// values for radio button
	Wave radioValues_plotThermo=root:app:radioValues_plotthermo
	// toggle switches as variables
	NVAR plotThermo_singleS_VAR=root:APP:plotThermo_singleS_VAR	//0/1 for all/single factor
	
	STRSWITCH (ctrlStruct.ctrlname)
		// all clicked
		CASE "radio_plotThermo_allS":
			radioValues_plotThermo[0]=1
			radioValues_plotThermo[1]=0
			
			SetVariable VarNUM_plotThermo_Snum, disable=2,win=MaSPET_Panel
			plotThermo_singleS_VAR=0
			
			BREAK
		// single clicked
		CASE "radio_plotThermo_singleS":
			radioValues_plotThermo[0]=0
			radioValues_plotThermo[1]=1
			
			SetVariable VarNUM_plotThermo_Snum, disable=0,win=MaSPET_Panel
			plotThermo_singleS_VAR=1
			BREAK
		DEFAULT:
			print "MPbut_radio_plotthermo_control: problem with strswitch"
			BREAK
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_plotThermo_allS, value=radioValues_plotThermo[0],win=MaSPET_Panel
	Checkbox radio_plotThermo_singleS, value=radioValues_plotThermo[1],win=MaSPET_Panel
ENDIF


END

//======================================================================================
//======================================================================================
// control radio button behaviour for bar plot and Tmax plot

FUNCTION MPbut_radio_plotbars_control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// values for radiobuttons
	Wave radioValues_plotBars=root:app:radioValues_plotBars
	// toggle switches as variables
	NVAR plotBars_type_VAR=root:APP:plotBars_type_VAR
	NVAR plotBars_Xtype_VAR=root:APP:plotBars_Xtype_VAR
	NVAR TmaxType_VAR=root:APP:TmaxType_VAR
		
	STRSWITCH (ctrlStruct.ctrlname)
		// absolute values clicked
		CASE "radio_PlotBars_abs":
			radioValues_plotBars[0]=1
			radioValues_plotBars[1]=0
			
			plotBars_type_VAR=0
			BREAK
		// relative values clicked
		CASE "radio_PlotBars_rel":
			radioValues_plotBars[0]=0
			radioValues_plotBars[1]=1

			plotBars_type_VAR=1
			BREAK
		//----------------------
		// absolute values clicked
		CASE "radio_PlotBars_cat":
			radioValues_plotBars[2]=1
			radioValues_plotBars[3]=0
			
			plotBars_Xtype_VAR=0
			BREAK
		// relative values clicked
		CASE "radio_PlotBars_time":
			radioValues_plotBars[2]=0
			radioValues_plotBars[3]=1
			
			plotBars_Xtype_VAR=1
			BREAK
		//----------------------
		// Tmax clicked
		CASE "radio_PlotTmax_max":
			radioValues_plotBars[4]=1
			radioValues_plotBars[5]=0
			
			TmaxType_VAR=0
			BREAK
		// median clicked
		CASE "radio_PlotTmax_median":
			radioValues_plotBars[4]=0
			radioValues_plotBars[5]=1
			
			TmaxType_VAR=1
			BREAK
		//----------------------
		DEFAULT:
			print "MPbut_radio_plotbars_control: problem with strswitch"
			BREAK
					
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_plotBars_abs, value=radioValues_plotBars[0],win=MaSPET_Panel
	Checkbox radio_plotBars_rel, value=radioValues_plotBars[1],win=MaSPET_Panel
	Checkbox radio_plotBars_cat, value=radioValues_plotBars[2],win=MaSPET_Panel
	Checkbox radio_plotBars_time, value=radioValues_plotBars[3],win=MaSPET_Panel
	Checkbox radio_PlotTmax_max, value=radioValues_plotBars[4],win=MaSPET_Panel
	Checkbox radio_PlotTmax_median, value=radioValues_plotBars[5],win=MaSPET_Panel
	
ENDIF


END

//======================================================================================
//======================================================================================

// control radio button behaviour for export time format

FUNCTION MPbut_radio_exportTime_Control(ctrlStruct) : CheckboxControl

STRUCT WMCheckboxAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	// values for radiobuttons
	Wave radioValues_exportTimeType=root:app:radioValues_exportTimeType

	// toggle switches as variables
	NVAR exportTimeType_VAR=root:APP:exportTimeType_VAR
	SVAR exportTimeformat_STR=root:APP:exportTimeformat_STR
		
	STRSWITCH (ctrlStruct.ctrlname)
		// absolute values clicked
		CASE "radio_export_Igor":
			radioValues_exportTimeType[0]=1
			radioValues_exportTimeType[1]=0
			radioValues_exportTimeType[2]=0
			
			exportTimeType_VAR=0
			BREAK
		// relative values clicked
		CASE "radio_export_matlab":
			radioValues_exportTimeType[0]=0
			radioValues_exportTimeType[1]=1
			radioValues_exportTimeType[2]=0
			
			exportTimeType_VAR=1
			BREAK
		//----------------------
		// absolute values clicked
		CASE "radio_export_text":
			radioValues_exportTimeType[0]=0
			radioValues_exportTimeType[1]=0
			radioValues_exportTimeType[2]=1
			
			exportTimeType_VAR=2
			BREAK
		DEFAULT:
			print "MPbut_radio_exportTime_Control: problem with strswitch"
			BREAK
					
	ENDSWITCH
	
	// upate radio button appearance
	Checkbox radio_export_Igor, value=radioValues_exportTimeType[0],win=MaSPET_Panel
	Checkbox radio_export_matlab, value=radioValues_exportTimeType[1],win=MaSPET_Panel
	Checkbox radio_export_text, value=radioValues_exportTimeType[2],win=MaSPET_Panel
	
	// enable/disable time format string
	IF (exportTimeType_VAR==2)
		//enable
		SetVariable VarTxt_exportTimeformat, disable=0
	ELSE
		// disable
		SetVariable VarTxt_exportTimeformat, disable=1	
	ENDIF
ENDIF



END

//======================================================================================
//======================================================================================

//======================================================================================
//		Help buttons
//======================================================================================

//======================================================================================


// Help button control
// identify selected help button and create help popup

FUNCTION MPbut_help_button_control(ctrlStruct): ButtonControl

STRUCT WMButtonAction &ctrlStruct

IF (ctrlStruct.eventCode==2)
	
	// temp text wave to hold help text -> each row = 1 line in help window
	MAke/FREE/T/N=30 HelpTxtWave=""
	
	// name of Help Panel window
	String helpPanelName=""
	
	// offset of the windows
	Variable Offset
	
	// value for Help window size
	Variable PanelHeight=350
	
	// identify help button
	STRSWITCH (ctrlStruct.ctrlname)
		// !!! for empty rows in th etext use HelpTxtWave[i]=" " (space!)
			
		//-----------------------------
		
		// data input
		
		// help for MStype radio buttons
		CASE "but_help_MStype":	
			offset=0
			
			helpPanelName="Help_for_MStype"
			HelpTxtWave[0]="\f01Select your data type"
			HelpTxtWave[1]="Selecting a MS type changes the visible items in the MaS-PET panel."
			HelpTxtWave[2]="The user can change the MS type at any point during the analysis"
			HelpTxtWave[3]="to gain access to any of the hidden features."
			HelpTxtWave[4]=" "
						
			HelpTxtWave[5]="\f04gas MS HR/UMR\f00: all purpose option for gas-phase and other data."
			HelpTxtWave[6]="\t\t\t\t\t\t\t\t\t\t\t\t Only select if your data is High resolution (HR)"
			HelpTxtWave[7]="\t\t\t\t\t\t\t\t\t\t\t\t or unit mass resolution (UMR)."
			HelpTxtWave[8]= "\f04FIGAERO TD\f00: for thermal desorption (thermogram) data sets that"
			HelpTxtWave[9]=	"\t\t\t\t\t\t\t\t\t\t contain one or more desorption cycles (=samples)."
			HelpTxtWave[10]= "\f04FIGAERO integrated\f00: time series of FIGAERO data integrated"
			HelpTxtWave[11]= "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t over each sample"
			HelpTxtWave[12]="\f04Aerosol MS\f00: designed for AMS and ACSM data."
			HelpTxtWave[13]="\t\t\t\t\t\t\t\t\tNote that use of PET functions may be required."
			
			Panelheight=5+20*13+20
			
			BREAK
		//-----------------------------	
		// help for explist wave
		
		CASE "but_help_expList":	
			offset=40
			
			helpPanelName="Help_for_expList"
			HelpTxtWave[0]="\f01SampleList Wave"
			HelpTxtWave[1]="MaS-PET can treat subsets of the data set individually. The actions "
			HelpTxtWave[2]="in Step 1 and 3 will operate on each data folder listed in this wave."
			HelpTxtWave[3]=" "
			
			HelpTxtWave[4]="If the data set is continuous (i.e., one sample), enter the name of the"
			HelpTxtWave[5]="data folder containing your data."
			HelpTxtWave[6]="If handling FIGAERO thermogram data, enter the names of the data "
			HelpTxtWave[7]="folders that each contain the data from 1 sample."
			HelpTxtWave[8]=" "
			HelpTxtWave[9]="To create a new wave, enter a new name and click 'show'"
			HelpTxtWave[10]="If you load your data with the 'Load Data' button, this wave can be "
			HelpTxtWave[11]= "generated automatically."
			
			Panelheight=5+20*11+20
			
			BREAK
		//-----------------------------	
		// help for wavenames
		CASE "but_help_wavenames":	
			offset=80
			
			helpPanelName="Help_for_WaveNames"
			HelpTxtWave[0]="\f01Set Wave Names"
			HelpTxtWave[1]="Provide the names of the Waves containing the input data."
			HelpTxtWave[2]="These wave names will be used for the actions in Step 1 and 2."
			HelpTxtWave[3]="Use the button to get the names from an existing 'Waves4PMF' wave."
			
			HelpTxtWave[4]=" "
			HelpTxtWave[5]="\f04MS Spec Data\f00: 2D matrix with mass spectra data."
			HelpTxtWave[6]="each row is one one mass spectrum, each column is one ion."
			HelpTxtWave[7]="\f04Error Matrix\f00: 2D matrix with error values. "
			HelpTxtWave[8]=	"Can be omitted until end of Step 1."
			HelpTxtWave[9]="\f04Time Series/Tdesorp\f00:Time or desorption temperture values."
			Helptxtwave[10]= "Used as x-axis values (i.e. equal to number of rows in data matrix)."
			HelpTxtWave[11]="\f04MZ values (NUM)\f00: numeric ion mass values. Used to identify ions."
			HelpTxtWave[12]="\f04ion Names (TXT)\f00: ion labels. If they are in a compatible format,"
			HelpTxtWave[13]="the elemental compositions of each ion will be calculated."
			HelpTxtWave[14]="\f04FIG. Time series\f00: Time series for FIGAERO thermogram data."
			HelpTxtWave[15]="Not used for PMF calcualtions, can be omitted."
			
			Panelheight=5+15*20+20
			
			BREAK
		//-----------------------------
		// step 1
		// help for splitting Samples & data prep
		CASE "but_help_prepData":	
			offset=120
			
			helpPanelName="Help_for_dataPrep"
			HelpTxtWave[0]="\f01Basic data preparation"
			HelpTxtWave[1]="Basic data preparation. Use if data set contains multiple (FIGAERO)"
			HelpTxtWave[2]="samples, or if error matrix needs to be calculated."
			HelpTxtWave[3]=" "
			HelpTxtWave[4]="\f04Split into samples\f00: only use if data set contains multiple samples."
			HelpTxtWave[5]="This separates each sample into its own subfolder using the names "
			HelpTxtWave[6]="in the 'SampleList' Wave. All following operations are applied to the "
			HelpTxtWave[7]="subfolders listed in this wave."
			HelpTxtWave[8]="Skip sample splitting if data set does not contain multiple samples."
			HelpTxtWave[9]="\f04prep data\f00: execute the following data preparation steps for all folders"
			HelpTxtWave[10]="listed in the 'SampleList' Wave."
			HelpTxtWave[11]="\t\t+ check if all selected waves are present and have the right format."
			HelpTxtWave[12]="\t\t+ convert the ion labels to numerical elemental composition."
			HelpTxtWave[13]="\t\t\f04the checkboxes select:"
			HelpTxtWave[14]="\t\t+ removing the mass of I- from MZ values where appropriate. "
			HelpTxtWave[15]="\t\t\tTo use these new values, change the name of the MZ values "
			HelpTxtWave[16]="\t\t\tWave to 'oldName_noi'"
			HelpTxtWave[17]="\t\t+ calculating the noise based (CN) error and provide the data for"
			HelpTxtWave[18]="\t\t\tthe PL error calculation. The user must interact with the PLerr "
			HelpTxtWave[19]="\t\t\tPanel to actually calculate the PL error values."
			HelpTxtWave[20]="\t\t\tRadio buttons switch between using only the end, all points or"
			HelpTxtWave[21]="\t\t\tonly points smaller than the median value for CNerror calculation."
			HelpTxtWave[22]="\t\t+ if selected the histogram data for the PL error calcualtion is "
			HelpTxtWave[23]="\t\t\tstored in each subfolder in ':SG_err'"
			
			Panelheight=5+23*20+20
			
			BREAK
		//-----------------------------
		// step 1
		// help for splitting Samples & data prep
		CASE "but_help_ionRemoval":	
			offset=120
			
			helpPanelName="Help_for_ionremoval"
			HelpTxtWave[0]="\f01Ion removal"
			HelpTxtWave[1]="Use these functions to remove specific ions from all samples when "
			HelpTxtWave[2]="creating the combined data set."
			HelpTxtWave[3]="Provide a name for the Index Wave with 1: remove ion, 0: keep it."
			HelpTxtWave[4]="'reset' resets the current Index Wave to 0 or creates a new one."
			HelpTxtWave[5]="You can choose ions by row index or ion Label (note exact spelling)."
			HelpTxtWave[6]="'include'/'remove' operate on the curerntly set ion."
			HelpTxtWave[7]="For FIGAERO-TD, ions are removed when combining samples."
			HelpTxtWave[8]="For all other data, duplicate waves without the selected ions are "
			HelpTxtWave[9]="created using the provided suffix."
			
			Panelheight=5+9*20+20
			
			BREAK
			
		//-----------------------------
		// Data loader
		// Loading data into the experiment
		
		// selecting file type
		CASE "but_help_DLFileType":	
			offset=120

			helpPanelName="Help_for_DL_fileType"
			HelpTxtWave[0]="\f01Loading data: file types"
			HelpTxtWave[1]="Select the file type you want to load. A set of files contains a file for " 
			HelpTxtWave[2]="each variable. All variables can be loaded at once, or individual "
			HelpTxtWave[3]="variables one at a time. You cannot load multiple file sets at once."
			HelpTxtWave[4]="If 'delimited text' is selected, also select the delimiter in your file."
			HelpTxtWave[5]="You may have to adjust the file extension for 'delimited text' from the."
			HelpTxtWave[6]="default (.csv) to your file type (e.g. .txt)"
			
			Panelheight=5+20*6+20
			
			BREAK
		//-----------------------------
		// selecting sample type for data
		CASE "but_help_DLsampletype":	
			offset=160

			helpPanelName="Help_for_DL_sampletype"
			HelpTxtWave[0]="\f01Loading data: number of samples"
			HelpTxtWave[1]="Indicate if the set of loaded files is one single data set or if it "
			HelpTxtWave[2]="contains multiplesamples (e.g. multiple FIGAERO desorption cycles)"
			HelpTxtWave[3]="For 'single' and 'multiple', extra steps are conducted after loading to"
			HelpTxtWave[4]="create the 'Waves with sample names' and Sample index automatically."

			Panelheight=5+20*4+20
			
			BREAK
		//-----------------------------
		// help on datafolders for loading
		CASE "but_help_DLfolders":	
			offset=200

			helpPanelName="Help_for_DL_folders"
			HelpTxtWave[0]="\f01Loading data: data folders"
			HelpTxtWave[1]="\f04source folder\f00: This folder on your disk will be searched for"
			HelpTxtWave[2]="files with the provided names."
			HelpTxtWave[3]="\f04Igor folder\f00: The loaded data will be stored in this Igor folder."
			HelpTxtWave[4]="If the 'overwrite' checkbox is selected, an existing data folder will be"
			HelpTxtWave[5]="overwriten without further checking. "
			
			Panelheight=5+20*5+20
			
			BREAK
		
		//-----------------------------
		// help on Input (wavenames, file names etc)	
		CASE "but_help_DLinput":	
			offset=240

			helpPanelName="Help_for_DL_input"
			HelpTxtWave[0]="\f01Loading data: Input and Wave names"
			HelpTxtWave[1]="Set the names of the files you want to load (without extension)."
			HelpTxtWave[2]="Leave the corresponding box empty to skip an input variable."
			HelpTxtWave[3]="Provide names for the loaded waves if you want. The names must not"
			HelpTxtWave[4]="contain any special characters except '_' ."
			HelpTxtWave[5]="All selected wave names are automatically transferred to the main"
			HelpTxtWave[6]="panel. Note that AMS and ACSM data from SQUIRREL or PIKA usually"
			HelpTxtWave[7]="have only 1 itx file which contains all waves. When loading an AMS or"
			HelpTxtWave[8]="ACSM itx file, the wave names saved in the file will be used."
			
			Panelheight=5+20*8+20
			
			BREAK
			
		//-----------------------------
		// help for time format	
		CASE "but_help_DL_timeformat":	
			offset=280

			helpPanelName="Help_for_DL_timeformat"
			HelpTxtWave[0]="\f01Loading data: Time format"
			HelpTxtWave[1]="When loading from a text file, select the format of the time values."
			HelpTxtWave[2]="\f04Igor\f00: Time values in Igor seconds."
			HelpTxtWave[3]="\f04Matlab\f00: Time values in Matlab datenum format."
			HelpTxtWave[4]="\f04String\f00: Time values as human readable text. "
			HelpTxtWave[5]="\t\t\t\t\tProvide the used format in the adjacent field."
			
			Panelheight=5+20*5+20
			
			BREAK
		//-----------------------------
		// PL error Panel
		// calculate PL error
		CASE "but_help_PLerrPanel":	
			offset=120

			helpPanelName="Help_for_PLerr"
			HelpTxtWave[0]="\f01Calculating PL errors"
			HelpTxtWave[1]="Inspect the values in the graph and select parameters for a power "
			HelpTxtWave[2]="law fit. The user can manually input parameter values in the boxes"
			HelpTxtWave[3]="or fit the data automatically.To remove a value for the fit, delete its "
			HelpTxtWave[4]="'Sij_all_all' value in the table below the graph. To restore deleted "
			HelpTxtWave[5]= "values, close and reopen the PLerr panel."
			HelpTxtWave[6]= " "
			HelpTxtWave[7]="\f04fit\f00: calculate a power law fit to the visible data using the constraints"
			HelpTxtWave[8]="\t\tselected with the checkboxes."
			HelpTxtWave[9]="\f04calc\f00: calculate the line described by the parameters in the boxes."
			HelpTxtWave[10]=" "
			HelpTxtWave[11]="\f04do PLerror\f00: calculate the PL error values for all subfolders listed in"
			HelpTxtWave[12]="the 'SampleList' wave. To use these new error values, the user must"
			HelpTxtWave[13]="change the name of the error matrix in the main panel."
			HelpTxtWave[14]="to 'oldName_PL'. Note that the minimum value of PL errors will be set "
			HelpTxtWave[15]="to the value indicated with the dashed line in the graph derived from"
			HelpTxtWave[16]="the noise of the data."
			
			Panelheight=5+20*16+20
			
			BREAK
			
		//-----------------------------
		// Step 2
		// handling negative values
		CASE "but_help_handleNegValues":	
			offset=160
			
			helpPanelName="Help_for_handling_neg_values"
			HelpTxtWave[0]="\f01Handling mostly negative values\f00"
			HelpTxtWave[1]="If background measurements were subtracted, ions can have "
			HelpTxtWave[2]="negative values. PMF tolerates negative values in the Mass Spectra"
			HelpTxtWave[3]="Data. Setting negative values to 0 is generally not recommended."
			HelpTxtWave[4]="If the majority of data points of an ion is negative in a sample, the"
			HelpTxtWave[5]="user may want to reduce the importance of that ion for that sample."
			HelpTxtWave[6]=" "
			HelpTxtWave[7]="The 'set ion to 0 if' button sets the values of ions to 0 if X % of their"
			HelpTxtWave[8]="data points are negative. Ions are only set to 0 for the samples that"
			HelpTxtWave[9]="meet the condition."
			
			Panelheight=5+20*9+20
			
			BREAK
		//-----------------------------
		// downweighing sample by sample
		CASE "but_help_Downweigh":	
			offset=200
			
			helpPanelName="Help_for_Downweighing"
			HelpTxtWave[0]="\f01MaS-PET downweighing"
			HelpTxtWave[1]="The Signal to Noise Ratio is calculated for each ion for each sample."
			HelpTxtWave[2]="If an ion has a SNR value smaller that the threshold, it will be "
			HelpTxtWave[3]="downweighted by the given factor."
			HelpTxtWave[4]="If the data set consists of one sample, this step is identical to Step 6 "
			HelpTxtWave[5]="in PET which always treats the data set as one sample."
			
			Panelheight=5+20*5+20
			
			BREAK
		//-----------------------------
		// what active folder does
		CASE "but_help_activeSolFolder":	 
			offset=120
			
			helpPanelName="Help_for_active_solution_folder"
			HelpTxtWave[0]="\f01Active Solution Folder"
			HelpTxtWave[1]="All steps after 'Extract solution' act on the folder set here."
			HelpTxtWave[2]="Clicking 'get solution' automatically sets the extracted folder."
			HelpTxtWave[3]="(do not use trailing ':')"
			HelpTxtWave[4]="Green/red box indicates if the chosen folder name exists."
			
			Panelheight=5+20*4+20
			
			BREAK
		//-----------------------------
		// what active folder does
		CASE "but_help_calcVariance":	 
			offset=120
			
			helpPanelName="Help_for_calcVariance"
			HelpTxtWave[0]="\f01Calculate Variance"
			HelpTxtWave[1]="calculate expected and unexpected Variance for all PMF solutions."
			HelpTxtWave[2]="Use radio buttons to select absolute or square distance method."
			
			Panelheight=5+20*2+20
			
			BREAK
		//-----------------------------
		// about extract solution
		CASE "but_help_extractSol":	
			offset=160
			
			helpPanelName="Help_for_extract_Solution"
			HelpTxtWave[0]="\f01Extract PMF solution"
			HelpTxtWave[1]="To enable more detailed analysis, individual solutions of the PMF"
			HelpTxtWave[2]="calculation in the selected data folder can be extracted into a "
			HelpTxtWave[3]="subfolder. Instead of 4D waves, only 1D and 2D waves are used."
			HelpTxtWave[4]="The time/Tdesorp series is split into the samples, if multiple samples"
			HelpTxtWave[5]="are listed in the 'SampleList' Wave."
			HelpTxtWave[6]=" "
			HelpTxtWave[7]="Select the number of factors and the fpeak/seed value for the"
			HelpTxtWave[8]="desired solution."
			
			Panelheight=5+20*8+20
			
			BREAK
		//-----------------------------
		// how compare solution works
		CASE "but_help_compareSol":
			offset=200
			helpPanelName="Help_for_compare_solutions"
			HelpTxtWave[0]="\f01Compare solutions"
			HelpTxtWave[1]="The data in the active solution folder is compared to the solutions"
			HelpTxtWave[2]="listed in the comparison wave."
			HelpTxtWave[3]="provide a new name in the box and press 'show' to create a new "
			HelpTxtWave[4]="comparison wave. The entries in the comparison wave must be the "
			HelpTxtWave[5]="full path to the solution folders which were extracted with MaS-PET"
			HelpTxtWave[6]=" "
			HelpTxtWave[7]="\f04Factor MS\f00: the factor mass spectra of two solutions are compared"
			HelpTxtWave[8]="pairwise. Their contrast angles are displayed to indicate similarity."
			HelpTxtWave[9]="A solution can be compared to itself to investigate the similarity of"
			HelpTxtWave[10]="its factor mass spectra."
			HelpTxtWave[11]="\f04tseries\f00: display the residuals between PMF results and measured "
			HelpTxtWave[12]="data as time/T series (i.e. integrated over all ions) for all solutions"
			HelpTxtWave[13]="listed in the comparison wave and the active solution folder"
			HelpTxtWave[14]="\f04mass spec\f00: same as 'tseries' but as mass spectrum (i.e integrated"
			HelpTxtWave[15]="over all time/T  points"
			HelpTxtWave[16]=""

			Panelheight=5+20*15+20
			
			BREAK

		//-----------------------------
		// mass spec plots
		CASE "but_help_mass":
			offset=260
			
			helpPanelName="Help_for_mass_spec_plots"
			HelpTxtWave[0]="\f01plotting factor mass spectra"
			HelpTxtWave[1]="Each button creates a visualisation of the factor mass spectra. Use"
			HelpTxtWave[2]="the radio button to switch between showing all or only a single factor."
			HelpTxtWave[3]=" "
			HelpTxtWave[4]="\f04sticks\f00: create the normal 'stick' mass spectra."
			HelpTxtWave[5]="\f04mass defect\f00: show the mass defect plot (HR data only)"
			HelpTxtWave[6]="\f04Kroll\f00: modified Kroll plot with symbol size indicating signal strength."
			HelpTxtWave[7]="\t\t\t\tOnly makes sense for data with identified ion sum formulas."
			HelpTxtWave[8]="\t\t\t\t'min' specifies the minimum signal strength to display"
			HelpTxtWave[9]="\f04grid\f00: grid version of modified Kroll plot."
						
			Panelheight=5+20*9+20
			
			BREAK
		//-----------------------------
		// tseries plots (including scaled diel
		CASE "but_help_tseries":
			offset=240
			
			helpPanelName="Help_for_tseries_plots"
			HelpTxtWave[0]="\f01Plotting tseries data"
			HelpTxtWave[1]="Display factor tseries related data."
			HelpTxtWave[2]=" "
			HelpTxtWave[3]="\f04by sample\f00: Display all factor tseries of each sample listed in the"
			HelpTxtWave[4]="\t\t\t\t\t\t\t  SampleList wave in a seperate panel. Use the radio"
			HelpTxtWave[5]="\t\t\t\t\t\t\t  buttons to draw all samples or only one specific sample. "
			HelpTxtWave[6]="\t\t\t\t\t\t\t  The number is the 0 based index in the SampleList Wave."
			HelpTxtWave[7]="\f04'time' series\f00: Plot all factor tseries in the data set vs the data index."

			HelpTxtWave[8]="\f04Scaled Diel\f00: diurnal pattern of the factor contributions. The data of"
			HelpTxtWave[9]="\t\t\t\t\t\t\t\t  each day is scaled to the mean value of the day before"
			HelpTxtWave[10]="\t\t\t\t\t\t\t\t  calculating the Diel values."
			
			Panelheight=5+20*10+20
			
			BREAK
		//-----------------------------
		// what per sample means for plotting
		CASE "but_help_plotPerSample":
			offset=240
			
			helpPanelName="Help_for_plot_per_Sample"
			HelpTxtWave[0]="\f01Calculations sample by sample"
			HelpTxtWave[1]="If multiple samples are present in the data set, the user can inspect"
			HelpTxtWave[2]="certain values calculated for each sample. The calcualtions are only "
			HelpTxtWave[3]="meaningful for FIGAERO-TD data sets!"
			HelpTxtWave[4]=" "
			HelpTxtWave[5]="\f04factor contribution\f00: show the contribution of each factor to each "
			HelpTxtWave[6]="\t\t\t\t\t\t\t\t\t\t\t\t\t sample calculated as the area under the factor "
			HelpTxtWave[7]="\t\t\t\t\t\t\t\t\t\t\t\t\t time/Tdesorp series per sample."
			HelpTxtWave[8]="\f04factor peak\f00: Tmax or Tmedian value of each factor thermogram. Only "
			HelpTxtWave[9]="\t\t\t\t\t\t\t\t\tmeaningful if the x values are desorption temperatures."
			HelpTxtWave[10]="\f04VBS\f00: display a pseudo VBS distribution of the factors for each sample"
			HelpTxtWave[11]="\t\t\t\tusing either Cstar values from calibration or 1/Tmax."
			HelpTxtWave[12]="\f04avg thermo\f00: average thermogram shape over multiple samples."
			HelpTxtWave[13]="\t\t\t\t\t\t\t\t  Averaging grid is set from min to max with grid width. "
			HelpTxtWave[14]="\t\t\t\t\t\t\t\t Only meaningful for multi smaple data sets."
			
			Panelheight=5+20*14+20
			
			BREAK
			
		//-----------------------------
		// what panels per column means
		CASE "but_help_panelsPerColumn":
			offset=280
			
			helpPanelName="Help_for_panelsPerColumn"
			HelpTxtWave[0]="Select the maximum number of panels stacked in one column."
			HelpTxtWave[1]="If more panels are needed, new columns will be created automatically."
			HelpTxtWave[2]="This applies to Time/T Series by sample plots, all factor mass spectra "
			HelpTxtWave[3]="plots, average Thermogram, factor peak, and scaled Diel plots."
			
			Panelheight=5+20*3+20
			
			BREAK

		//-----------------------------
		// export to text
		CASE "but_help_export2txt":
			offset=320
			
			helpPanelName="Help_for_export2txt"
			HelpTxtWave[0]="\f01Export G & F Matrices"
			HelpTxtWave[1]="The G and F matrices, time/temperature series and ion information "
			HelpTxtWave[2]="are exported for the selected Active Solution folder."
			HelpTxtWave[3]="Set desired format for time/temperature series with the radio buttons."
			HelpTxtWave[4]="Select checkbox to also export the MSdata and MSerror matrices."
			
			Panelheight=5+20*4+20
			
			BREAK
		
		//-----------------------------
		DEFAULT:
			print "unable to determine type of help button"
			print ctrlStruct.ctrlname
			BREAK
		
	ENDSWITCH
		
	// open help window if it is not there
	// if it is there (second click) close it
	
	String TestStr=winlist(helpPanelName,";","")
	IF (!Stringmatch(TestStr,""))
		// kill window
		Killwindow/Z $helpPanelName
	ELSE
		// create Panel if it does ont exist
	
		NewPanel/K=1/W=(1300,50+offset,1750,50+offset+PanelHeight)/N=$helpPanelName as helpPanelName
		
		// loop through helptxtwave to write into help popup
		Variable ii
		String titleBoxName=""
		Variable yoffset=20
		
		FOR (ii=0;numpnts(helpTxtWave)-1;ii+=1)
			IF (!stringmatch(HelpTxtWave[ii],""))
				// name of title box
				titleBoxName=helpPanelName+"_"+num2Str(ii)
				// write each line
				TitleBox $(titleBoxName) pos={10,5+yoffset*ii},title=HelpTxtWave[ii],fstyle= 0,fsize= 14,frame=0,font="Arial",win=$helpPanelName
			ELSE
				//emtpy row -> break
				BREAK
			ENDIF
		ENDFOR
	ENDIF
ENDIF

END

