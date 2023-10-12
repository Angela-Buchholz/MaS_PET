#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

//======================================================================================
//	MaS_PET_Main is the top layer of the MaS-PET software. 
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

// VERSIONS:
// MaS-PET:	2.04
// PET:		3.08C

// Purpose:	Start-up routine for MaS-PET (Mass Spectrometry data PMF Evaluation Toolkit)
//			This was designed to simplify the pre-and post-processing of mass spectrometry data for PMF analysis
//			The actual PMF calculation is done via Aerodyne's PET 
//
//			This routine prompts the user for the Version number of PET and MaS-PET and the loads the relevant procedures from Igor User Procedure folders
//				 		
// Input:	version number of PET and MaS_PET
//				
// Output in Igor:	loads all relevant routines



//======================================================================================
//======================================================================================
// create Menu entry

Menu "MaS_PET"

	"get started", MPstart_selectVersion()
End

//======================================================================================
//======================================================================================

// Purpose:		prompt user for Version numbers and load procedure files
// Input:		Version numbers aas String via GUI
// 				
// Output :		loads all relevant routines

FUNCTION MPstart_selectVersion()

// version numbers must be String becasue PET can have letter
String Version_MAS="2.04"
String Version_PET="3.08C"
String Version_SNR="1.02"

Prompt  Version_MAS,"MaS-PET:"
Prompt  Version_PET,"PET:"
Prompt Version_SNR,"SNR Panel:"

String helpStr="Set Version numbers for Mas-PET and PET.\rFormat should be \"1.01\" or \"1_01\".\rQuotation murks must be included.\rNote that PET Version may include a letter."

DoPrompt /Help=helpStr "Select Version", Version_PET,Version_SNR,Version_MaS

IF (V_flag==1)	// user canceled
	Abort	// normal abort becasue MPaux_abort does not exist yet !
ENDIF

// clean up Version String
Version_PET=replaceString(".",Version_PET,"_")
Version_SNR=replaceString(".",Version_SNR,"_")
Version_Mas=replaceString(".",Version_Mas,"_")

// Procedure file names	(order of files is important to avoid compilation errors!)
String funcfileStr=""
String PET_Proclist="PMF_ViewResults_v;PMF_SetupPanel_v;PMF_ErrPrep_AMS_v;PMF_Execution_v;PMF_Scatter_v;PMF_EACode_v;"
String MAS_ProcList="MaS_PET_main_v;MaS_PET_ButtonFuncs_v;MaS_PET_AuxFuncs_v;MaS_PET_PrepFuncs_v;MaS_PET_postFuncs_v;MaS_PET_plotting_v;"

Variable pp=0

// check if new version number exists
// PET

// list with ALL procedures in User Procedure folder
String Proclist=MPstart_GetAllUserProcs("IgorUserFiles")	// this is slow. BUt no better idea for now

String searchName="(?i)"+Stringfromlist(0,PET_Proclist)+Version_PET+".ipf"

String searchResult=Greplist(Proclist,searchName)

IF (Itemsinlist(SearchResult)==0)
	abort "No PET functions file found with version number:\r\r"+Version_PET+"\r-> check your User Procedures folder for available version"
ENDIF

// MaS-PET
searchName="(?i)"+Stringfromlist(0,MaS_Proclist)+Version_MaS+".ipf"

searchResult=Greplist(Proclist,searchName)

IF (Itemsinlist(SearchResult)==0)
	abort "No MaS-PET functions file found with version number:\r\r"+Version_MaS+"\r->check your User Procedures folder for available version"
ENDIF


// load functions with this info
//-------------------------------

#if (IgorVersion() >= 8.03 )	// Turn Autocompile off to prevent compile errors
	Execute/P "AUTOCOMPILE OFF "  
#endif		
	
// PET (must be first because MaS_PET_main contains some PET things)

// check for existing functions with different version
String ListOfFuncs=Functionlist("pmfCalcs_viewPanel",";","")	// search for one provcedure in PMF_Setup_Panel_vX_XXi

IF (itemsinlist(ListOfFuncs)>0)	// some functions are already open
	
	// check version
	String Info_PET=FunctionInfo(Stringfromlist(0,ListOfFuncs))
	String OldVersion_Pet=StringByKey("PROCWIN",Info_PET)
	OldVersion_Pet=Stringfromlist(1,OldVersion_Pet,"Panel_v")	// get version number
	OldVersion_Pet=removeending(OldVersion_Pet,".ipf")
	
	// if it is not the same -> remove entries
	IF (!stringmatch(OldVersion_Pet,Version_PET))	

		FOR(pp=0;pp<itemsinlist(PET_Proclist);pp+=1)	// loop through procedures
			
			funcfileStr="DELETEINCLUDE \""+Stringfromlist(pp,PET_Proclist)+OldVersion_Pet+"\""
			Execute/P/Z/Q funcfileStr		
		
		ENDFOR
	
	ENDIF
ENDIF

// and add new ones
FOR(pp=0;pp<itemsinlist(PET_Proclist);pp+=1)	// loop through procedures
	
	funcfileStr="INSERTINCLUDE \""+Stringfromlist(pp,PET_Proclist)+Version_PET+"\""
	Execute/P/Z/Q funcfileStr		

ENDFOR
	
funcfileStr="INSERTINCLUDE \"SNRAnalysis_v"+Version_SNR+"\""	// so far this has not changed
Execute/P/Z/Q funcfileStr

//-------------------------------
// MaS-PET

ListOfFuncs=Functionlist("MPmain_showMAS_PET_PANEL",";","")	// search for one procedure in PMF_Setup_Panel_vX_XXi

IF (itemsinlist(ListOfFuncs)>0)	// some functions are already open
	
	// check version
	String Info_MaS=FunctionInfo(Stringfromlist(0,ListOfFuncs))
	String oldVersion_MaS=StringByKey("PROCWIN",Info_MaS)
	oldVersion_MaS=Stringfromlist(1,oldVersion_MaS,"_main_v")	// get version number
	oldVersion_MaS=removeending(oldVersion_MaS,".ipf")
	
	// if it is not the same -> remove entries
	IF (!stringmatch(oldVersion_MaS,Version_MaS))	

		FOR(pp=0;pp<itemsinlist(MaS_Proclist);pp+=1)	// loop through procedures
			
			funcfileStr="DELETEINCLUDE \""+Stringfromlist(pp,MaS_Proclist)+OldVersion_MaS+"\""
			Execute/P/Z/Q funcfileStr		
		
		ENDFOR
	
	ENDIF
ENDIF

// and add new ones
FOR(pp=0;pp<itemsinlist(MaS_Proclist);pp+=1)	// loop through procedures
	
	funcfileStr="INSERTINCLUDE \""+Stringfromlist(pp,MaS_Proclist)+Version_MaS+"\""
	Execute/P/Z funcfileStr		

ENDFOR
	
// compile now that everything is there
Execute/P/Z/Q "COMPILEPROCEDURES "

// auto compile back on
#if (IgorVersion() >= 8.03 )
	Execute/P "AUTOCOMPILE ON "  
#endif		

END


//======================================================================================
//======================================================================================

// Purpose:		create a list of all procedure files in the Igor User Folder
//				string with all found procedure files is returned with ; seperated list
// 				Adapted from GetAllFilesRecursivelyFromPath
// 				https://github.com/AllenInstitute/MIES/blob/31b2bdd7722bd66bb8f412a86317c1b71dcd424b/Packages/MIES/MIES_Utilities.ipf#L2968
// Input:		pathName:	IgorUserFolder path object
// 				
// Output :		string with all found procedure files is returned with ; seperated list


Function/S MPstart_GetAllUserProcs(pathName)

	string pathName	// is needed for next iteration
	
	String extension=".ipf"

	string fileOrPath, directory, subFolderPathName
	string files
	string allFiles = ""
	string dirs = ""
	variable i, numDirs

	PathInfo $pathName
	IF (V_flag==0)
		abort "Given symbolic path does not exist"
	ENDIF
	
	for(i = 0; ;i += 1)
		fileOrPath = IndexedFile($pathName, i, extension)

		if(strlen(fileOrPath)==0)
			// no more files
			break
		endif

		fileOrPath = MPstart_ResolveAlias(pathName, fileOrPath)

		if(strlen(fileOrPath)==0)
			// invalid shortcut, try next file
			continue
		endif

		GetFileFolderInfo/P=$pathName/Q/Z fileOrPath
		IF (V_flag!=0)
			abort "Error in GetFileFolderInfo"
		ENDIF
		
		if(V_isFile)
			allFiles = AddListItem(S_path, allFiles, ";", INF)
		elseif(V_isFolder)
			dirs = AddListItem(S_path, dirs, ";", INF)
		else
			//ASSERT(0, "Unexpected file type")
		endif
	endfor

	for(i = 0; ; i += 1)

		directory = IndexedDir($pathName, i, 1)

		if(strlen(directory)==0)
			break
		endif

		dirs = AddListItem(directory, dirs, ";", INF)
	endfor

	numDirs = ItemsInList(dirs, ";")
	for(i = 0; i < numDirs; i += 1)

		directory = StringFromList(i, dirs, ";")
		subFolderPathName = MPstart_GetUniqueSymbolicPath()

		NewPath/Q/O $subFolderPathName, directory
		files = MPstart_GetAllUserProcs(subFolderPathName)
		KillPath/Z $subFolderPathName

		if(strlen(files)!=0)
			allFiles = AddListItem(files, allFiles, ";", INF)
		endif
	endfor

	// remove empty entries
	return ListMatch(allFiles, "!", ";")
End


//======================================================================================
//======================================================================================

// Purpose:		resolve short cuts in User folder
// Input:		path name and resolved path
// 				
// Output :		resolved path name (where th eshortcut is leading to)

// called by:	MPstart_GetAllUserProcs()

Function/S MPstart_ResolveAlias(pathName, path)
	string pathName, path

	GetFileFolderInfo/P=$pathName/Q/Z path

	if(V_flag)
		return ""
	endif

	if(V_isAliasShortcut)
		return MPstart_ResolveAlias(pathName, S_aliasPath)
	endif

	return path
End

//======================================================================================
//======================================================================================

// Purpose:		create new symbolic path for something
// Input:		prefix: optional prefix for the folder name
// 				
// Output :		generated Symbolic path

// called by:	MPstart_GetAllUserProcs()

Function/S MPstart_GetUniqueSymbolicPath([prefix])
	string prefix

	if(ParamIsDefault(prefix))
		prefix = "temp_"
	endif

	SetRandomSeed/BETR=1 ((stopmstimer(-2) * 10 ) & 0xffffffff) / 2^32
	
	variable randomSeed

	do
		randomSeed = abs(enoise(1))
	while(randomSeed == 0)

	return prefix + num2istr(randomSeed * 1e6)
End

//======================================================================================
//======================================================================================

