<# 
.Synopsis
	Function to write object(s) (or strings derived from them) to one or more output streams, such as: file, logfile, verbose, debug, output, xml
.Description
	Function to write object(s) to any defined output, such as display them to the host screen.
	Function allows for displaying text to screen in different colors.
	Entries in the log file are linked and time stamped. Verbose output is preceded by caller name between brackets.
	Blanks are removed from the end of strings, so put them in front if you want blanks to appear between different object.
.Parameter Object
	The object(s) to be written
.Parameter To
 The Write option(s) to perform
	Valid options are:	
						Append		= [io.file]::AppendText $AppendPath
						Debug		= Write-Debug				Stream 5
						Error		= Write-Error				Stream 2
						Replace		= [IO.StreamWriter]($ReplacePath)
						Host		= Write-Host				Stream 6 as of PowerShell 5.0, passed to host program in PowerShell 1.0-4.0
						Information	= Write-Information			Stream 6 as of PowerShell 5.0
						Log			= [io.file]::AppendText $LogPath
			Default:	Output		= Write-Output				Stream 1
						Verbose		= Write-Verbose				Stream 4
						Warning		= Write-Warning				Stream 3
						Xml			= Export-CliXml
	Write options may be abbreviated to a single letter (such as H,L,O or even HLO = Host,Log,Output) if the result is unambiguous
.Parameter ForeGroundColor (Alias FG)
	The foregroundcolor(s) to be used in Host output. The colors will repeat if there are fewer colors than objects
	Default is White
	Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, Red, White, Yellow
.Parameter AttentionLevel (Alias AL)
	Character (I, W, C, E or F) representing the attention text (INFO, WARNING, CAUTION, ERROR, FATAL)
	If present, the corresponding attention text will be inserted before each object in Host, Log and Verbose output
	If absent or invalid, nothing will be inserted
.Parameter AppendPath (Alias AP)
	Path to the file where the object(s) should be appended
	Example: c:\append.txt
	If absent or appendpath name is invalid, no objects will be appended to AppendPath, warning message via Write-Debug
.Parameter LogPath (Alias LP)
	Path to the LogFile where the log entries should be appended
	Example: c:\ProjectX\MyScript.log
	If $LogPath does not exist as a parameter, an attempt is made to retrieve its value from $Script:LogPath and $Global:LogPath
	If absent or Logpath name is invalid, no objects will be appended to LogPile, warning message via Write-Debug
	A line in a logfile consists of a security chain (6 bytes), the date and time of the log entry and the message.
.Parameter ReplacePath (Alias RP)
	Path to the file where the object(s) should be written
	Example: c:\replace.txt
	If absent or Replacepath name is invalid, no objects will be written to ReplacePath, warning message via Write-Debug
.Parameter XmlPath (Alias XP)
	Path to the XmlFile where the Xml-converted object should be appended
	Example: c:\log.txt
	If absent or Xmlpath name is invalid, no objects will be written to XmlPath, warning message via Write-Debug
.Parameter Join
	String to join object items together in output to Host output. If absent, every object item is written out separately.
.Parameter NoNewLine (Alias NONL)
	Switch indicating that output to Host (if specified as a write option) will not insert a NewLine at the end of its output.
	If absent, a NewLine will be added
.Parameter SeparatorLine (Alias SL)
	String to be used as Separatorline in Host, File and Log output. If absent, no separatorline will be added.
.Parameter AttentionLevel (Alias AL)
	Character (I, W, C, E or F) representing the attention text (INFO, WARNING, CAUTION, ERROR, FATAL)
	If present, the corresponding attention text will be inserted before each object in Host, Log and Verbose output.
	If absent or invalid, nothing will be inserted.
.Example
	Write-It "Hello World" -To Host,Log -ForegroundColor Yellow -LogPath 'c:\log.txt'
	This example displays the "Hello World" string to the screen in yellow, and adds it as a new line to the file c:\log.txt.
	If 'c:\log.txt' does not exist it will be created.
	Log entries in the log file are chained and timestamped up to milliseconds.
	Sample Log output: 546884 20210303-102052.404 Hello World
.Example
	$x = Write-It (Get-Location).Path
	or
	$x = (Get-Location).Path | Write-It
	This example passes the object(s) to Write-Output, which can then be processed
.Example
	Write-It 'Hello',' brave',' new',' world!' -to h green,yellow -nonl
	This example passes the object(s) to Write-Host, putting them all on one line and altering the color between green and yellow
.Example
	"$((Get-Process | select -First 1).name) process ID is $((Get-Process | select -First 1).id)" | Write-It -To Host -fg DarkYellow -sl ('-'*80)
	Sample output of this example:
	ApMsgFwd process ID is 5768 (in dark yellow), followed by a separatorline of 80 hyphens
.Example
	Write-It 'Found'," $((Get-ChildItem -Path .\ -File).Count)",' files in folder'," $((Get-Item .\).FullName)" | Write-It -To Host -fg Green,Yellow,Green,Cyan -nonl
	Sample output will look like:
	Found 23 files in folder U:\ (and foregroundcolors change for each item of the array object)
.Example
	$z = @(1,2,3),@{1='Call';2='Help'} | Write-It -to Information 6>&1
	Convert arguments to string, write them to stream 6 via Write-Information, redirect stream 6 to stream 1 and assign to variable $z

.Example
	Write-It @(1,2,3),@{1='Call';2='Help'} -to Xml -XmlPath 'C:\MyXml.txt'
	Writes passed object(s) to file 'C:\MyXml.txt' in CliXml format (can be retrieved by cmdlet Import-CliXml)
.Note
	VERSION
	v1.0.0 - 2018-03-09
	v1.0.1 - 2018-03-23		Speed up looping and writes to files
							use "Append" and "Replace" instead of "File"
	v1.0.2 - 2021-01-13		Correct checking file fullnames (at least 4 bytes long and format must be 'X:\etc')
	v1.0.3 - 2021-03-03		Security chain for log entries
#>
Function Write-It
{
[CmdletBinding()]
Param	(
		[Parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)][ValidateNotNull()][Object[]]$Objects, 
		[Parameter(Mandatory=$false)][String[]]$To='Output', 
		[Parameter(Mandatory=$false)][Alias('FG')][ConsoleColor[]]$ForeGroundColor = 'White', 
		[Parameter(Mandatory=$false)]$Join,
		[Parameter(Mandatory=$false)][Alias('AL')][Char]$AttentionLevel,
		[Parameter(Mandatory=$false)][Alias('AP')][String]$AppendPath,
		[Parameter(Mandatory=$false)][Alias('LP')][String]$LogPath,
		[Parameter(Mandatory=$false)][Alias('RP')][String]$ReplacePath,
		[Parameter(Mandatory=$false)][Alias('XP')][String]$XmlPath,
		[Parameter(Mandatory=$false)][Alias('SL')][String]$SeparatorLine,
		[Parameter(Mandatory=$false)][Alias('NONL')][Switch]$NoNewLine
		)
Begin
	{
	Function Calculate-String ([string]$string,[int]$seed=0,[int]$length)
	{
	[int[]]$int = ([System.Text.Encoding]::UTF8).GetBytes($string)
	$res=$seed;for ($i=1;$i -le $int.count;$i++) {$res+=$i*$int[$i-1]};[string]$res = $res.ToString();if ($length -and $length -lt $res.length) {$res=$res.substring(0,$length)};$res
	}
	Function Resolve-Abbreviation
	{
	[CmdletBinding()]
	Param	(
			[Parameter(ValueFromPipeline=$true,Position=0)][Alias('Exp')][String[]]$Expanded,
			[Parameter(Position=1)][String]$Split,
			[Parameter(Position=2)][Alias('Abb')][String[]]$Abbreviated,
			[switch]$Char
			)
	Begin	{if		($Char)			{$Abbreviated = $Abbreviated.ToCharArray()}}
	Process	{if		($Split)		{$Expanded = $Expanded -Split $Split}
			switch	($Abbreviated)	{{$Expanded -like "$_*"}{$Expanded -like "$_*"}}
			}
	}
	$RegexStart							= '^'								# Start of string, nothing is allowed to precede
	$RegexWindowsDrive					= '[A-Za-z]:'						# Drive letter followed bij colon ('X:')
	$RegexWindowsFolder					= '(?:\\[^\\<>/*?":|]+)+\\?'		# at least one group containing 1 backslash followed by none of the characters '\<>/*?":|', optionally followed by 1 backslash
	$RegexWindowsFileName				= '[^\\<>/*?":|]+'					# none of the characters '\<>/*?":|'
	$RegexPoint							= '\.'								# Escape character '\' needed because '.' has special meaning
	$RegexWindowsExtension3To8			= '[^\\<>/*?":|]{3,8}'				# 3 to 8 characters, none of them '\<>/*?":|'
	$RegexEnd							= '$'								# End of string, nothing is allowed to follow
	$RegexWindowsFileFullPath			= $RegexStart + $RegexWindowsDrive + $RegexWindowsFolder + $RegexWindowsFileName + $RegexPoint + $RegexWindowsExtension3To8 + $RegexEnd
	$Options = @('Append','Debug','Error','Host','Information','Log','OutPut','Verbose','Warning','Xml')
	$ToOptions = Resolve-Abbreviation -Expanded $Options -Abbreviated $To
	if		(!$ToOptions)
			{$ToOptions = Resolve-Abbreviation -Expanded $Options -Abbreviated $To -Char}
	foreach ($Option in 'Append','Log','Replace','Xml')
			{
			if	($ToOptions -contains $Option)
				{
				$OptionPath = Get-Variable -Name "$($Option)Path" -ValueOnly -ErrorAction 'Ignore'
				if		(!$OptionPath)
						{
						Remove-Variable -Name "$($Option)Path" -Scope 0 -ErrorAction 'Ignore'
						$OptionPath = Get-Variable -Name "$($Option)Path" -ValueOnly -ErrorAction 'Ignore'
						}
				if		(($OptionPath.Length -le 4)	-or ($OptionPath -notmatch $RegexWindowsFileFullPath))
						{
						Write-Debug "$Option`: Missing or bad $($Option)Path name '$OptionPath', nothing will be written to $Option file"
						$ToOptions = $ToOptions -ne $Option
						}
				}
			}
	$AttentionText = switch	($AttentionLevel)
							{
							''		{break}
							'I'		{'INFO:    ';break}
							'W'		{'WARNING: ';break}
							'C'		{'CAUTION: ';break}
							'E'		{'ERROR:   ';break}
							'F'		{'FATAL:   ';break}
							Default	{Write-Debug "AttentionLevel '$AttentionLevel' invalid, accepted options are: I, W, C, E or F"}
							}
	}
Process
	{
	switch	($ToOptions)
			{
			'Host'			{
							foreach	($Object in $Objects)
									{
									$FGColor = $ForeGroundColor[$Objects.IndexOf($Object) % $ForeGroundColor.Count]
									$Object = $Object |
											Out-String -Stream |
											Where-Object {$_} |
											ForEach-Object {"$($_.TrimEnd())"}
									if		(($null -ne $Join) -and ($Object.Count -gt 1))
											{
											$Object = $Object -join $join
											}
									foreach	($Index in (0..($Object.Count - 1)))
											{
											if		($Object.Count -gt 1)
													{
													if		($Index -eq 0 -and $AttentionText)
															{Write-Host "$AttentionText$Object[$Index]" -ForegroundColor $FGColor}
													else	{Write-Host $Object[$Index] -ForegroundColor $FGColor}
													}
											else	{Write-Host "$AttentionText$Object" -ForegroundColor $FGColor -NoNewLine}
											}
									if		(!$NoNewLine)
											{Write-Host
											if		($SeparatorLine)
													{Write-Host $SeparatorLine}
											}
									}
							if		($NoNewLine)
									{Write-Host}
							continue
							}
			'Append'		{
							$Append =	$Objects | 
										ForEach-Object	{
														$_
														if		($SeparatorLine)
																{$SeparatorLine}
														} |
										Out-String -Stream
							$AppendWriter = [io.file]::AppendText($AppendPath)
							foreach ($Line in $Append)
									{$AppendWriter.WriteLine($Line)}
							$AppendWriter.Close()
							$AppendWriter.Dispose()
							continue
							}
			'Debug'			{
							$Objects |
							Out-String -Stream |
							Where-Object {$_} |
							ForEach-Object {"$($_.TrimEnd())"} |
							Write-Debug
							continue
							}
			'Error'			{
							$Objects |
							Out-String -Stream |
							ForEach-Object {"$($_.TrimEnd())"} |
							Write-Error
							continue
							}
			'Information'	{
							foreach	($Object in $Objects)
									{
									$Items =	$Object |
												Out-String -Stream
									foreach	($Item in $Items)
											{
											if		($Item)
													{Write-Information -MessageData $Item}
											}
									}
							continue
							}
			'Log'			{
							$Log =	$Objects |
									ForEach-Object	{
													if		($AttentionText)
															{"$AttentionText$_"}
													else	{$_}
													if		($SeparatorLine)
															{$SeparatorLine}
													} |
									Out-String -Stream
							if		([System.IO.File]::Exists($LogPath))
									{$Chain = ((Get-Variable -Name LogLastLine -ValueOnly -EA ignore) + '540404').substring(0,6)}
							else	{$Chain = (Calculate-String ([System.IO.Path]::GetFileName($LogPath)) 0 3) + (Calculate-String $Env:UserName 0 3)}
							$LogWriter = [io.file]::AppendText($LogPath)
							foreach ($Line in $Log)
									{if		($Line)
											{
											$WriteLine = "$(Calculate-String $Line $Chain 6) $(Get-Date -format 'yyyyMMdd-HHmmss.fff') $($Line.TrimEnd())"
											$LogWriter.WriteLine($WriteLine)
											Set-Variable -Name LogLastLine -Scope Script -Value $Writeline.substring(0,6)
											}										
									}
							$LogWriter.Close()
							$LogWriter.Dispose()
							continue
							}
			'Output'		{
							$Objects |
							Write-Output
							continue
							}
			'Replace'		{
							$Replace =	$Objects | 
										ForEach-Object	{
														$_
														if		($SeparatorLine)
																{$SeparatorLine}
														} |
										Out-String -Steam
							$ReplaceWriter = [IO.StreamWriter] $ReplacePath
							foreach ($Line in $Replace)
									{$ReplaceWriter.WriteLine($Line)}
							$ReplaceWriter.Close()
							$ReplaceWriter.Dispose()
							continue
							}
			'Verbose'		{
							$CallStack = Get-PSCallStack
							if		($CallStack.Count -gt 1)
									{$Parent = $CallStack[1].FunctionName}
							else	{$Parent = 'None'}
							$Objects |
							Out-String -Stream |
							Where-Object {$_} |
							ForEach-Object	{
											if		($AttentionText)
													{"($Parent) $Attentiontext$($_.TrimEnd())"}
											else	{"($Parent) $($_.TrimEnd())"}
											} |
							Write-Verbose
							continue
							}
			'Warning'		{
							$Objects |
							Out-String -Stream |
							Where-Object {$_} |
							ForEach-Object {"$($_.TrimEnd())"} |
							Write-Warning
							continue
							}
			'Xml'			{
							Export-CliXml -InputObject $Objects -Depth 99 -Path $XmlPath -WhatIf:$false
							continue
							}
			}
	}
}