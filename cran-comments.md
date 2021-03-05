# Submission
## Test environments
* local windows 10 install, R 4.0.4
* debian 10, R 4.0.4 and devel
* win-builder (devel and release)

## R CMD check results
There were two NOTEs and no ERRORs or WARNINGs.

NOTE
Imports includes 31 non-default packages.
Importing from so many packages makes the package vulnerable to any of them becoming unavailable. Move as many as possible to Suggests and use conditionally.

I checked all packages and none can be moved from imports.

Found the following (possibly) invalid URLs:
  URL: http://loosolab.mpi-bn.mpg.de/ (moved to https://github.molgen.mpg.de/pages/loosolab/www/)
    From: README.md
    Status: 200
    Message: OK
  URL: http://loosolab.mpi-bn.mpg.de/wilson (moved to http://loosolab.mpi-bn.mpg.de/wilson/)
    From: README.md
    Status: 200
    Message: OK
    
The URLs are correct.

## Downstream dependencies
I have also run R CMD check on downstream dependencies of wilson 
(https://gitlab.gwdg.de/loosolab/software/wilson/tree/master/revdep).
All packages that I could install passed.
