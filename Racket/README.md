# Racket language CML benchmarks

Folder containing the files for the Racket language benchmarks.

## Executing these programs

Currently, the way to execute these programs is to run them on the command line, with the Racket interpreter.  E.g. to execute the MonteCarloPi program on Windows (where this particular one has been developed), you would use:

```powershell
$(PATH TO RACKET EXECUTABLE)\Racket.exe -tm .\montecarlopi.rkt $(NUM ITERATIONS) $(NUM THREADS)
```

where `$(PATH TO RACKET EXECUTABLE)` is the location of the Racket executable file (on the current computer it is "C:\Program Files\Racket"); `$(NUM ITERATIONS)` is the desired number of iterations for the program to run; and $(NUM THREADS) is the number of CML threads required to be used.  `-tm` are flags to the Racket executable - the details aren't important here, just know they need to be included.  The other programs will all follow much the same pattern.

## Parameters to each program

Monte Carlo Pi takes, in order, the number of iterations and the number of threads to use.
