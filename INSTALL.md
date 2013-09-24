Installing Poor Man Central SCAP
================================

Server side - Configuration repository
--------------------------------------

Create a directory structure with _at least_ the `config/` directory in it, and
expose it either through a file share or through a web server.

Create the necessary configuration file(s) for the target systems. For instance,
to use open-scap on a particular host and send the results to an HTTP server, 
the following file could be saved as `config/hosts/myhost.mydomain.com.conf`:

```
scapscannerxccdf=oscap xccdf eval --profile @@STREAMID@@ --oval-results --results @@XCCDFRESULTNAME@@ @@STREAMNAME@@
scapscannerxccdf_noprofile=oscap xccdf eval --results @@XCCDFRESULTNAME@@ @@STREAMNAME@@
scapscanneroval=oscap oval eval --id @@STREAMID@@ --results @@OVALRESULTNAME@@ @@STREAMNAME@@
scapscanneroval_noid=oscap oval eval --results @@OVALRESULTNAME@@ @@STREAMNAME@@
platform=Gentoo Linux
keywords=
resultrepo=https://ascapresults/cgi-bin/savefile.py?target=@@TARGETNAME@@&filename=results/@@DATE@@/@@FILENAME@@
```

Server side - Reporting repository
----------------------------------

Create a directory structure where the results are to be saved. If the reporting
repository will be file system based, then use the following `resultrepo` syntax
for the configuration file:

```
resultrepo=file:///mnt/nfs/results/@@DATE@@/@@TARGETNAME@@/@@FILENAME@@
```

If the reporting repository is a web server (in which case pmcs will use the
`filecontent` form variable for the file in a POST message) then the repository
can be something like the one given above (see Configuration repository).

Target side - pmcs agent
------------------------

Install the `pmcsa.sh` script on the target systems, ensuring that the necessary
software (*nc*, *wget* and *curl*) are available in the PATH. Create a
scheduling entry (such as a crontab entry) for daily execution, like with the
following crontab example:

```
# Run pmcsa at 3:10 am
10 3 * * *   pmcsa.sh https://ascapconfig/pmcs
```

