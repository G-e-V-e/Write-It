# Write-It
Write string(s) or object(s) to multiple streams: host, output, warning, verbose, debug, error.
Logfile append (chained and timestamped) XmlFile output, other file append/replace.
Support WhatIf for file operation.

If you ever wished you could write a message to the console, log it and also assign it to a variable all in one go, then this is your solution.

Interactive quick fix scripts have enough ways to visualise what they do and why, but when it comes to unattended production scripts, they should be as extrovert as possible, certainly when something goes wrong, either due to unexpected results or due to a terminating error. Adding output after every critical action can lenthen the script considerably and distract from the program logic. So, if you can, just add 1, mostly 2 lines to communicate what has to be communicated and go on with it.

In its most basic form, function Write-it accepts a string and outputs it to the stream(s) you specified.
