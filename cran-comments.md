# Submission
This is a resubmission based on the feedback from the previous review.

## Test environments
* local windows 11 install, R 4.6.1
* debian 13, R 4.5.3
* win-builder (devel and release)

## R CMD check results
There were two NOTEs and no ERRORs or WARNINGs.

NOTE
>Package was archived on CRAN

This is a re-submission of an archived Package. I've removed the archived package requirement (log4r).

>Possibly misspelled words in DESCRIPTION:
   Omics (3:30)
   omics (9:132)

The words are checked and spelled correctly.

## Reviewer notes

>Functions which are supposed to only run interactively (e.g. shiny) should be wrapped in if(interactive()). Please replace /dontrun{} with if(interactive()){} if possible, then users can see that the functions are not intended for use in scripts.
For more details: 
<https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples> 

The respective example is now runnable.

>Please ensure that your functions do not write by default or in your examples/vignettes/tests in the user's home filespace (including the package directory and getwd()). This is not allowed by CRAN policies. 
Please omit any default path in writing functions. In your examples/vignettes/tests you can write to tempdir().
For more details: 
<https://contributor.r-project.org/cran-cookbook/code_issues.html#writing-files-and-directories-to-the-home-filespace>

Stripped default path from file writing function and redirected test outputs to temp.
