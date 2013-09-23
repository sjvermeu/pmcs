Poor Man Central SCAP Agent
===========================

In this directory you will find one, perhaps later multiple scripts that all
implement the pmcsa logic in their own way. Considering its simple design, it
might be sufficient to stick with the scripted approach. If not, it'll change
later to C code.

Design
------

### Usage ###

```
~$ pmcsa [-d <port>] <repo-urn>
``` 

The `-d` option is to daemonize the agent.

### Streams ###

The streams refered to later have the following syntax:

```
<type>#<streampath>#<id>
```

If `<type>` is `xccdf`, then `<id>` is the profile name of the XCCDF

If `<type>` is `oval`, then `<id>` is the OVAL id

### Pseudo code - scheduled run ###

The following pseudo code shows how pmcsa functions for the scheduled run.

```
FQDN      = get system fully qualified hostname
DOMAIN    = get system domain name (or "localdomain" if empty)
CLASS     = get system class
LOCALDATE = get system date (YYYYMMDD format)

POSSIBLE_TARGETS = 
  <repo-urn>/config/domains/DOMAIN.conf
  <repo-urn>/config/classes/CLASS.conf
  <repo-urn>/config/domains/DOMAIN/classes/CLASS.conf
  <repo-urn>/config/hosts/FQDN.conf

Fetch configuration from POSSIBLE_TARGETS (overriding values):
  PLATFORM                = get platform from configuration
  KEYWORDS                = get keywords from configuration (comma separated)
  RESULTREPO              = get resultrepo from configuration
  SCAPSCANOVAL            = get scapscanneroval from configuration
  SCAPSCANOVAL_NOID       = get scapscanneroval_noid from configuration
  SCAPSCANXCCDF           = get scapscannerxccdf from configuration
  SCAPSCANXCCDF_NOPROFILE = get scapscannerxccdf_noprofile from configuration


STREAM_LISTS = 
  <repo-urn>/stream/hosts/FQDN/list.conf
  <repo-urn>/stream/domains/DOMAIN/classes/CLASS/platforms/PLATFORM/list.conf
  <repo-urn>/stream/domains/DOMAIN/classes/CLASS/list.conf
  <repo-urn>/stream/classes/CLASS/platforms/PLATFORM/list.conf
  <repo-urn>/stream/classes/CLASS/list.conf
  <repo-urn>/stream/domains/DOMAIN/list.conf
  [ for each KEYWORD in KEYWORDS: <repo-urn>/stream/keywords/KEYWORD/list.conf ]

STREAMS = Concatenate stream identifiers from all list.conf files

for each STREAM in STREAMS
  STREAMTYPE     = STREAM[0] # separated
  STREAMPATH     = STREAM[1] # separated
  STREAMID       = STREAM[2] # separated
  DATASTREAMFILE = fetch <repo-urn>/stream/STREAMPATH

  ## SCAPSCAN{STREAMTYPE} -> depends on type!
  ## (_NO*)? if no id or profile given
  {XCCDFRESULT, OVALRESULT}       = evaluate DATASTREAMFILE using SCAPSCAN{STREAMTYPE}(_NO*)?
    Substitute @@STREAMNAME@@ with path to DATASTREAMFILE
    Substitute @@XCCDFRESULTNAME@@ with path to XCCDFRESULT
    Substitute @@OVALRESULTNAME@@ with path to OVALRESULT
    Substitute @@STREAMID@@ with STREAMID
  send XCCDFRESULT to RESULTREPO if exists
    Substitute @@TARGETNAME@@ with FQDN
    Substitute @@FILENAME@@ with XCCDFRESULT file name
    Substitute @@DATE@@ with LOCALDATE value
  send OVALDSRESULT to RESULTREPO if exists
    Substitute @@TARGETNAME@@ with FQDN
    Substitute @@FILENAME@@ with OVALRESULT file name
    Substitute @@DATE@@ with LOCALDATE value
```

As the evaluation of a data stream could lead to multiple result files (one
xccdf result file and one oval result file), we need to support retrieval of
both. Hence the `DSRESULT` and `DSRESULT2` variables.

### Pseudo code - ad-hoc run ###

```
(Reuse configuration from earlier part)

Bind webserver-functionality on PORT (argument)

for each REQUEST
  if REQUEST != (GET|HEAD) /Evaluate?type=STREAMTYPE&path=STREAMPATH&id=STREAMID HTTP/1.(0|1)
    ignore request
  STREAMTYPE = get STREAMTYPE from REQUEST
  STREAMPATH = get STREAMPATH from REQUEST
  STREAMID   = get STREAMID from REQUEST

  write "STREAMTYPE#STREAMPATH#STREAMID" in STREAMS
  
  (reuse STREAM handling code from previous part)
```
