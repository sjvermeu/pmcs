Poor Man Central SCAP Design
============================

Components
----------

pmcs uses four components

* The central configuration repository stores the configuration entries for the
  various hosts and the SCAP content to be executed against the target systems.
  The configuration files are stored in a `config/` folder whereas the streams
  are stored in a `stream/` folder.
* The pmcs agent is a locally-executed script that, if executed in scheduled
  mode, will pull in the configuration from the central configuration repository
  and then download the stream(s) that are applicable to the system. Then a
  local SCAP scanner is used to evaluate the streams after which the pmcs agent
  sends the results to a central result repository
* On the local system a local SCAP scanner has to be installed. pmcs does not
  provide such a scanner, but has been succesfully tested with open-scap and
  ovaldi. Any SCAP scanner that can be triggered using command-line should be
  easily supported - all that is needed is to put the right command in the
  (centrally managed) configuration.
* The central result repository captures the OVAL and XCCDF results for further
  processing.


Central configuration repository
--------------------------------

The central configuration repository holds the configuration files of the
targets as well as the SCAP content to be evaluated on the targets.

### Configuration files ###

The configuration files are stored in a `config/` folder; the pmcs agent will
look for various configuration entries, starting from a course-grained setting
(based on the network DNS domain name) up to the host-specific variables.

This allows administrators to set general parameters (such as the command to
evaluate SCAP content) at a high level, while setting particular variables on a
per-host system.

The pmcs agent will fetch the configuration from the following set of URIs, in
the given order, and will evaluate _all_ entries. All variables, except for
`keyword=`, will be overruled by the settings in the later evaluated
configuration files.

- config/domains/${DOMAIN}.conf
- config/classes/${CLASS}.conf
- config/domains/${DOMAIN}/classes/${CLASS}.conf
- config/hosts/${FQDN}.conf

The variables in this list are captured from the host itself by pmcs:
* `${DOMAIN}` is the DNS domain name of the system. On a Unix system, this
  is obtained through the *dnsdomainname* command. If no domainname is provided,
  the script will use "localdomain".
* `${CLASS}` is the SCAP class to which the system belongs; valid families
  currently are `unix` and `windows`.
* `${FQDN}` is the fully qualified domain name of the system.

The configuration files can/should set the following variables:

* `platform=` to set the platform of a system. Examples:

```
platform=Gentoo Linux
platform=Microsoft Windows 2013 Server
```

* `resultrepo=` to set the target location where OVAL and XCCDF results should
  be sent to. Examples:
```
resultrepo=file:///mnt/nfs/scapresults/@@DATE@@/@@TARGETNAME@@/@@FILENAME@@
resultrepo=http://results.mydomain.com/cgi-bin/savefile.py?target=@@TARGETNAME@@&filename=scapresults/@@DATE@@/@@TARGETNAME@@/@@FILENAME@@
```

* `scapscanneroval=` and `scapscannerxccdf=` are the command line instructions
  to evaluate the OVAL or XCCDF content. These instructions are executed when
  the configuration (which will be discussed later) passes on the OVAL id or XCCDF
  profile to be evaluated against.
* `scapscanneroval_noid=` and `scapscannerxccdf_noprofile=` is similar to
  `scapscanneroval=` and `scapscannerxccdf=` but for when no OVAL id or XCCDF
  profile is provided. Examples:
```
scapscannerxccdf=oscap xccdf eval --profile @@STREAMID@@ --oval-results --results @@XCCDFRESULTNAME@@ @@STREAMNAME@@
scapscannerxccdf_noprofile=oscap xccdf eval --results @@XCCDFRESULTNAME@@ @@STREAMNAME@@
scapscanneroval=oscap oval eval --id @@STREAMID@@ --results @@OVALRESULTNAME@@ @@STREAMNAME@@
scapscanneroval_noid=oscap oval eval --results @@OVALRESULTNAME@@ @@STREAMNAME@@
```

* `keywords=` is an append-only variable (i.e. it is never overruled, only
  appended to) that administrators can use to "tag" certain systems (or set of
  systems) allowing for a more granular approach to SCAP scanning across a large
  set of systems. The variable is comma-separated. Examples:
```
keywords=web,dmz
```

### Streams and stream lists ###

Next, the pmcs agent will get an overview of SCAP data streams that it needs to
evaluate. The lists are obtained through the following URIs (all hits are
evaluated).

* stream/hosts/${FQDN}/list.conf
* stream/domains/${DOMAIN}/classes/${CLASS}/platforms/${PLATFORM}/list.conf
* stream/domains/${DOMAIN}/classes/${CLASS}/list.conf
* stream/classes/${CLASS}/platforms/${PLATFORM}/list.conf
* stream/classes/${CLASS}/list.conf
* stream/domains/${DOMAIN}/list.conf
* stream/keywords/${KEYWORD}/list.conf

The `${PLATFORM}` variable is the one assigned through the configuration (as
mentioned earlier) but where special characters (such as spaces) are changed
with underscores.

The URI with `${KEYWORD}` is evaluated for each keyword assigned to the system.

### list.conf syntax ###

The `list.conf` file obtained from the repository uses the following syntax:

```
<type>#<resultid>#<streamfile>#[<id>]
```

* The `<type>` is either `oval` or `xccdf` and informs the pmcs agent which type
  of SCAP content is going to be evaluated.
* The `<resultid>` is a _unique_ identifier that identifies how the result files
  should be stored. XCCDF results will be stored as `<resultid>-xccdf-results.xml`
  whereas OVAL results are stored as `<resultid>-oval-results.xml`.
* The `<streamfile>` is the relative URI, starting from the `stream/` folder,
  that the agent will need to fetch.
* The `<id>` is an optional identifier telling the agent what OVAL id or XCCDF
  profile should be used.

An example list file:

```
oval#vuln#classes/unix/vulnerabilities.xml#
xccdf#pgsql-scb#domains/localdomain/benchmarks/postgresql-benchmark.xml#xccdf_org.gentoo.dev.swift_profile_default
oval#inventory#domains/localdomain/classes/unix/inv.xml#oval:org.gentoo.dev.swift:def:4432
```

pmcs agent
----------

The pmcs agent is a simple script that pulls the information from the central
configuration repository, evaluates the streams and then sends the results to a
central result repository.

More details about its design (including pseudo-code) can be found in the
`bin/pmcsa` directory.

Local SCAP scanner
------------------

For local SCAP scanning, tools such as open-scap (*oscap*) or ovaldi can be
used.

Central result repository
-------------------------

The central result repository obtains the result files from the systems and
stores them on its file system. Although definitely not mandatory, the following
hierarchical structure can help simplify reporting later:

```
  scapresults
  `- <date>
     `- <host>
```

If you need post-processing on the results, it makes sense that all results for
a particular day are contained within a single directory tree.
