@echo off
echo | compile-run-c: Compiling %1...
gcc %1 -o %~n1.exe
if %errorlevel% equ 0 (
    echo | compile-run-c: Running %~n1.exe...
    %~n1.exe
) else (
    echo | compile-run-c: Compilation failed.
)
echo | compile-run-c: Running %~n1.exe finished.