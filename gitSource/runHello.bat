@echo off


set vHOME=C:\public

set vPRJ=%vHOME%\orga\udemy\CSharp
set vFWK=%SystemRoot%\Microsoft.NET\Framework64

set vCPL=%vFWK%\v4.0.30319\csc.exe

:: test
set vBIN=%vPRJ%\Hello\bin\Debug\netcoreapp3.1\Hello.exe

set vNAM=Program
set vPGM=%vPRJ%\Hello\%vNAM%.cs
set vEXE=%vNAM%.exe

set vRUN=%vCPL% %vPGM%

@echo **** run Hello
%vRUN%
dir  %vEXE%
