snippets2oval.sh
================

Introduction
------------

The `snippets2oval.sh` script creates OVAL files based on the snippets found in
various sub directories. It uses the definition(s) in the `definitions/`
location, parses them and then starts building the OVAL file by including the
referred snippets from other directories.

Usage
-----

```
~$ snippets2oval.sh /path/to/basedir
``` 

Configuration
-------------

The base directory, of which an example is provided in this repository (see
`example/scaprepo/custom`), has to contain the following:

* `data/` directory, containing two files: `oval_pre` and `oval_post`, which
  is the start and end of the oval file (XML structure)
* `definitions/` directory, containing definition snippets.
  Each snippet is called `ID_some_information_about_the_file.xmlsnippet`
  where ID reflects the ID value of the definition.
* `objects/`, `states/`, `tests/` and `variables/` directories which
  contain the snippets for these OVAL parts. Again, each file starts with
  `ID_` followed by some explanation
* `oval/` is the target directory where (finished) OVAL files will be displayed.

The resulting OVAL file will be named after the definition file.

Shortages and bugs
------------------

Currently, the script assumes that all referred objects, states, variables and
such are all of the same namespace.
