XSL Reports
===========

We use XSL to generate the reports in the format needed. 

Usage
-----

The `genreport.sh` script takes three arguments:

* The directory where the results are stored
* The directory where the XSL report files are stored
* The directory where the HTML (or other output) reports should be stored

```
~$ genreport.sh /srv/www/upload /usr/share/lib/pmcs/xsl /srv/www/reports
```

Results
-------

The report generation will create numerous CSV files that can be used to build
initial reports.

At the base location, `definitions.csv` is created which contains the
description of each definition found. In the subdirectory `definitions`, each
definition (but with `:` changes by `_`) has both its XML structure (as text
file) as well as its dependencies (the file ending with `_definitions.csv`).
