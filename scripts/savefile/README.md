Save File CGI Script
====================

The savefile.py Python script is a simple CGI script that implements the
necessary logic to save files to the file system. It can be used as the
destination for the results repository.

Usage
-----

This script can be used as a target repository. Just update the `BASEDIR`
variable in it to point to the right location. You can use the embedded CGI web
server provided by Python if you want.

The repository URL to use with pmcs could look like so:

```
resultrepo=http://targetserver/cgi-bin/savefile.py?target=@@@TARGETNAME@@@&filename=results/@@FILENAME@@
```

You can use `@@DATE@@` in the URL as well, or have the logic (for storing the
per-day results) in the CGI script itself.
