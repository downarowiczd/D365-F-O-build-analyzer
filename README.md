# D365 F&O BuildAnalyzer
![Icon](images/extension-icon.png)
Analyzes the output logs of the compiler and best practices for warnings, information, and todos to provide a build summary about them.

[![Build extension](https://github.com/downarowiczd/D365-F-O-build-analyzer/actions/workflows/buildExtension.yml/badge.svg)](https://github.com/downarowiczd/D365-F-O-build-analyzer/actions/workflows/buildExtension.yml)

If desired, the task will then fail if certain conditions are met. 
Currently, the task has three options:
* Fail on a BP check
* Fail on warnings from the compiler
* Fail on obsolete warnings
![Build Analyzer Options](images/build-analyzer-options-V0.png)



# Build results tab
This extension also adds a build results tab to the pipeline results page, where the user can see an overview of how many occurrences of BP, compiler, metadata and todo warnings there are in the models. In addition, all warnings are listed in tables below the summary. 

***Please excuse the basic design of the result page. I'm not a web designer and tried to do my best with my backend developer knowledge.***

![Build result page](images/build-result-page.png)