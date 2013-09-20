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

The `-id` option is to daemonize the agent.

### Pseudo code - scheduled run ###

The following pseudo code shows how pmcsa functions for the scheduled run.

```
FQDN   = get system fully qualified hostname
DOMAIN = get system domain name
CLASS  = get system class

POSSIBLE_TARGETS = 
  <repo-urn>/config/domains/DOMAIN.conf
  <repo-urn>/config/classes/CLASS.conf
  <repo-urn>/config/domains/DOMAIN/classes/CLASS.conf
  <repo-urn>/config/hosts/FQDN.conf

Fetch configuration from POSSIBLE_TARGETS (overriding values):
  PLATFORM   = get platform from configuration
  KEYWORDS   = get keywords from configuration (comma separated)
  RESULTREPO = get resultrepo from configuration
  SCAPSCAN   = get scapscanner from configuration

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
  DATASTREAMFILE = fetch <repo-urn>/stream/STREAM
  DSRESULT       = evaluate DATASTREAMFILE using SCAPSCAN
    Substitute @@STREAMNAME@@ with path to DATASTREAMFILE
    Substitute @@RESULTNAME@@ with path to DSRESULT
  send DSRESULT to RESULTREPO
    Substitute @@TARGETNAME@@ with FQDN
    Substitute @@FILENAME@@ with DSRESULT file name
```
