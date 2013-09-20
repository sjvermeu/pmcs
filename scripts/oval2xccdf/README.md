oval2xccdf
==========

Some tools only work from an XCCDF file and are not able to run OVAL directly
(I'm looking at you, CIS-CAT).

This script will create an XCCDF file that "just" refers to the OVAL files and
definitions in them.

Usage
-----

```
~$ oval2xccdf.sh <oval-files>
```

All definitions in the list of OVAL files will be included.

Building a SCAP data stream
---------------------------

The result of this script can be used to build a SCAP data stream using
open-scap:

```
~$ oval2xccdf.sh *-oval.xml > xccdf.xml
~$ oscap ds sds-compose xccdf.xml ds.xml
```

The resulting `ds.xml` file is the data stream.
