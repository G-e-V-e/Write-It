# Write-It
Write object(s) to multiple streams, such as host, output, warning, verbose, debug, error.
Logfile append (chained and timestamped), XmlFile output, other file append/replace.
Support WhatIf for file operations (except Xml).

If you ever wished you could write a message to the console, log it and also assign it to a variable all in one go, then this is your solution.

Interactive quick fix scripts have enough ways to visualise what they do and why, but when it comes to unattended production scripts, they should be as extrovert as possible, certainly when something goes wrong, either due to unexpected results or due to a terminating error. Adding output after every critical action can make the script considerably longer and distract from the program logic. So, if you can, just add 1, mostly 2 lines to communicate what has to be communicated and go on with it.

In its most basic form, function Write-it accepts a string object and outputs it to the stream(s) you specified.

The -To streams can be specified in full, abbreviated or as a string of first characters. So, specifying h,ou,log or even 'hol' is the same as Host,Output,Log, resulting in Write-Host, Write-Output and Write to the logfile.

Note that objects passed thru a pipeline come in element by element, so get treated as separate objects, whereas objects following the -Object parameter are treated as a whole.

Output written to Host, Log and Verbose streams can be preceded by an AttentionText as the result of an optional AttentionLevel parameter:
  I = Info, W = Warning, C = Caution, E = Error, F = Fatal

Output written to Host, Log, Append and Replace streams can be followed by a separator line between objects as the result of an optional -Separator parameter:
  By creating a separator string (such as '=========') you specify that you want a separator line between objects.  

* When you specify Output as output stream, that output is added to the result of function Write-It and can be assigned to a variable in the calling script.
* When you specify Host as output stream, you have a couple of extra parameters to play with:
  -ForeGroundColor: parameter can be specified as an array, resulting in colors switching between objects, elements or even characters.
  -NoNewLine: output on the same line where the previous output ended.
  -Join: when specified, objects will be joined together using the join string.
* When you specify Log as output stream, you can pass the full path as -LogPath parameter, however that is not required if variable $LogPath exists in the calling script.
  Log output consists of a 6-byte chaining string, a datetimestamp, an optional AttentionText and the object to be written.
* When you specify Append as output stream, you also have to specify parameter -AppendPath.
* When you specify Replace as output stream, you also have to specify parameter -ReplacePath.
* When you specify Xml as outputn you also have to specify parameter -XmlPath.
* Empty elements are suppressed before writing to the Host, Log, Debug, Verbose and Warning streams.
* Trailing blank characters are trimmed before writing to the Host, Error and Warning streams.
