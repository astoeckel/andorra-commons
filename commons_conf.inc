{
* This program is licensed under the Common Public License (CPL) Version 1.0
* You should have recieved a copy of the license with this file.
* If not, see http://www.opensource.org/licenses/cpl1.0.txt for more
* informations.
*
* Inspite of the incompatibility between the Common Public License (CPL) and
* the GNU General Public License (GPL) you're allowed to use this program
* under the GPL.
* You also should have recieved a copy of this license with this file.
* If not, see http://www.gnu.org/licenses/gpl.txt for more informations.
*
* Project: Andorra 2D
* Author:  Andreas Stoeckel
* File: commons_conf.inc
* Comment: This file is used for configuring Andorra Commons. Simply copy this file
  to your project directory and add it to your project directory.
  Deactivate or activate the compiler switches as you like.
}

//IMPORTANT! HOW TO USE THE CONFIGURATION FILE!
//If you do not want to use the settings in this file for all Andorra 2D projects,
//rename this file in the Andorra 2D source directory and copy this file to your Andorra 2D
//projects.

{$IFNDEF ANDORRA_CONF}
{$DEFINE ANDORRA_CONF}

//--------------------------------
//--- ANDORRA ASM SETTINGS ---

//Remove ' if you do not want to use 3DNOW!. This may lead to problems with AMD processors.
//If any problem occurs deactivate this compiler switch and report this problem.
{'$DEFINE DO_NOT_USE_3DNOW}

//Remove ' if you do not want to use any x86 ASM code
{'$DEFINE DO_NOT_USE_ASM}

{$ENDIF}

