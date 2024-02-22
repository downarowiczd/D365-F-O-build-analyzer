# D365 F&O build analyer
![Icon](images/extension-icon.png)
Analyzes the compiler and best practice output logs for warnings, informations and ToDos to provide a build summary about them.

[![Build extension](https://github.com/downarowiczd/D365-F-O-build-analyzer/actions/workflows/buildExtension.yml/badge.svg)](https://github.com/downarowiczd/D365-F-O-build-analyzer/actions/workflows/buildExtension.yml)

If wished the task will then fail on certain conditions. 
Currently the task has three options:
* Fail on BP check
* Fail for compiler warnings
* Fail for obsolete warnings
![Build analyzer options](images/build-analyzer-options-V0.png)



# Build result tab
This extension also adds a build results tab to the pipeline result page where the user can see an overview of how many occurences of BP, compiler, metadata and todo warnings are in his models. And on top of that all warnings are listed in tables under the overview. 

***Please excuse me for the basic design of the result page, I'm not a web designer and I tried doing my best with my backend developer knowledge***

![Build result page](images/build-result-page.png)
