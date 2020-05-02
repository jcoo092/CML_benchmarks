# CML_benchmarks
The code and other assorted files pertaining to my attempts to benchmark parallel Concurrent ML (CML) processing in a handful of languages.

NB:  This README is very much incomplete.  I plan to expand it more when I actually have finished most of the programming work.  Also, while I certainly would appreciate advice on the best use of a given language, I may or may not actually implement it here.  Since I am not overly familiar with any of the languages involved, there is an extra (implicit) test of the languages with regards to which is best for allowing non-expert users derive good performance from them.  Thus, while you are free to raise an issue suggesting an improvement and I certainly will listen to what you have to say, I don't guarantee that I will actually incorporate that into my programs.  I also **won't** be accepting any pull requests from other people for the time being.

The end goal of this work is to select a language with a CML implementation (whether it calls it that or not) for my purposes of testing that approach against more traditional approaches with regards to certain Stereo Vision algorithms.  To perform this test, I am writing a variety of small programs that test various relevant aspects of the languages and their CML implementations.

Currently, I am considering four languages (in alphabetical order):  Guile Scheme, MLton, OCaml and Racket (both Typed and regular).  These were the four languages I could identify which apparently have full (or pretty close to full) support for *parallel* CML, and met a number of other criteria.

## CML vs Communicating Sequential Processes
In recent times, there has been quite an explosion of interest in Communicating Sequential Processes (CSP), likely largely driven by Go's inclusion of channels and goroutines as part of its core.  You should note that CML is *not* equivalent to CSP.  Arguably, in a practical sense CML is a superset of CSP.  While CSP implementations do typically have synchronous channels and message passing etc, CML takes it further and makes synchronisation itself a full value in the language (with 'events' in Reppy's parlance).  This is similar to how most modern programming languages take a leaf out of functional programming and make functions themselves full values that can be passed around like other variables, i.e. incorporate higher-order functions.

## Exemplar programs
Each sub-repository contains implementations of six separate small programs (or will do, once its finished) that are intended to test one or more aspects of the language and its CML implementation.  They are mostly focused on testing the speed of various aspects of CML communication and processing, with two exceptions.

## Benchmarking process
Benchmarking in this repository is performed using the [hyperfine](https://github.com/sharkdp/hyperfine) command-line program.  The choice to use a command-line tool, instead of one built into/supplied with each language was made to ensure the best possible comparability.  Generally speaking, benchmarking and profiling tools for a given language tend to be focused on assisting developers working in that language to improve their programs.  Furthermore, they may make assumptions about the language, which probably won't be reasonable in other languages.  Thus, a language-neutral benchmarking approach is required.
