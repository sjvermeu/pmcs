Poor Man Central SCAP
=====================

Introduction
------------

When working with SCAP content for its various use cases, there are already a
few open source projects that provide us with SCAP scanners. Open-SCAP is able
to test OVAL and XCCDF documents, but only locally (thus far). Ovaldi is a
similar one.

What is missing is a way to centrally work on SCAP content, having multiple
systems pull the necessary definitions from the central repository, "play" it
locally and send back the results to a central location.

There, on this central location, the reports can then be aggregated further to
make proper architectural decisions with a wider view on the situation, rather
than having to parse the reports individually.

Central management of SCAP content
----------------------------------

SCAP 1.2 already provides a way to have a single stream (SCAP data streams)
containing all SCAP content needed for a local system to properly test all that
is needed.

pmcs will use SCAP data streams by bundling the XCCDF, OVAL, CPE (and in the
future other protocols as well) for each target based on a prepared definition,
and offering the SCAP data stream as a single HTTP(S) resource. It is however no
hard requirement that the data is in SCAP data stream format: we can easily just
pass OVAL files and use those as long as they are "contained".

Local SCAP scanners pull the SCAP data stream(s) needed for the system, based on
a set of system parameters (hostname, domainname, platform, class and generic
keywords). They evaluate the SCAP data stream(s) and send back the reports
towards a central repository.

Currently, the two "central" locations supported are regular file systems (in
case of file shares), using "file://" as the "remote" pointer, and web servers,
using "http://" or "https://" as "remote" pointer.

What pmcs provides
------------------

With pmcs, security administrators can manage SCAP scanning across a large set
of systems using the _local_ SCAP scanner software (i.e. SCAP scanner software
installed on the target system) using a simple wrapper that pulls in the
necessary SCAP data streams, runs the necessary tests and sends the results
towards a central location again.

### Why local SCAP scanner software ###

Local SCAP scanner software is more available than SCAP scanners that use remote
scanning. Tools such as Open-SCAP [http://www.open-scap.org] or Ovaldi
[http://sourceforge.net/projects/ovaldi/] are perfectly usable locally and offer
a wide set of supported OVAL tests.

### Why should I use a centralized approach? ###

When you are dealing with only a handful of systems, there is no need to
centrally manage running SCAP tests. You just have the SCAP content (OVAL or
XCCDF files) on those systems and occasionally run the SCAP scanner to get
information about the state of your system(s).

But the moment you need to manage this across a large environment, this becomes
troublesome:
* how do you get the SCAP content on all those systems?
* will you log on on each of those systems to run the scanner if you need to
  quickly get information about a certain vulnerability?
* will you go fetch the results on each system towards your workstation to check
  its results?

By centrally provisioning the SCAP content (which, in case of pmcs, is either on
a network share or on a web server) and getting the results (OVAL results or
XCCDF test results) back on a central location, the security administrator can
focus on creating proper SCAP content and interpreting the SCAP results without
having to think about distributing and running the SCAP content on all systems.

### How do I configure pmcs ###

One of the focus areas of pmcs is that the local components use SCAP scanners
already available. The first focus is on Open-SCAP and Ovaldi, but others should
be easy to integrate as we are focusing on the SCAP technologies.

The local pmcs agent has two roles: scheduling regular SCAP evaluations, and
waiting for triggers to do ad-hoc evaluations.

The scheduled evaluation is no daemonized agent; it has to be
scheduled from a scheduler such as Cron, Windows Task Scheduler or even more
enterprise job schedulers. But we will support the daemonized approach as well
where the admin can trigger evaluations.

Only a single parameter should be passed on to the agent: the URN towards the
central configuration repository. For instance (pmcsa = pmcs agent):
```
~$ pmcsa https://cscapserver.localdomain/repo
```

The agent will then pull in the necessary information from this location. This
is one of the advantages of pmcs - it uses a configuration-less approach to
handling the scanners. Well, not exactly configuration-less, but the
configuration is also managed centrally.

Once information is obtained, the agent will download the SCAP content that it
needs to evaluate, evaluate it, and send the results to a central repository
(which does not need to be the same URN as the central configuration
repository).

### I can ask for immediately executed scans? ###

Sometimes administrators want to push out certain checks towards one or more
systems without having to wait for a particular scheduled run. We need to
support this, which means that the pmcsa (pmsc agent) will also support a
daemonized setup to which administrators can push evaluation requests.

### How to scan remote systems ###

Later editions of pmcsa will support remote scanning as well. In these setups,
the pmcsa agent pulls in the remote list. This list contains the evaluations
(xccdf or oval) that need to be done, but also an additional parameter called
the _target list_.

This target list contains the ID of the target, the encryption type of the
remainder of the data, and then a list of key/value pairs which will be used
as environment variables. That means that the scans that will be executed
(one for each ID) will be done with the given environment variables loaded.

What pmcs does not provide
--------------------------

With pmcs, you do not get any tools or methods for creating the SCAP content
itself (although pointers are given as simple scripts and documents) nor will
you get tools (yet) that help process the results.

### Generating SCAP content ###

Generating SCAP content can be achieved either by directly downloading it from
one of the SCAP repositories (just use your favorite search engine and look for
"oval repository" or so) or creating it yourself with an XML editor (or just a
simple text editor).

If you downloaded OVAL files, a script is provided in pmcs that creates an XCCDF
file that refers to all tests in the OVAL files. This is not needed in order to
run OVAL scans, but if you want to create a SCAP data stream using open-scap,
you need an XCCDF file:

```
~$ oscap ds sds-compose my-xccdf-file.xml
```

### Parsing and interpreting OVAL and XCCDF results ###

The result files sent back from the targets still needs to be interpreted. The
easiest way is to directly build the reports from the files, which you can do
using ovaldi or open-scap or any of the other SCAP tools that provide reports.

As the files are XML files, anyone with some XSL expertise can build their own
reports on the results.

We might add in a component to pmcs later to support reporting on the results,
but for now the only provided methods are quite ugly and are mostly as try-outs.

Needed expertise
----------------

In order to use pmcs, you will need to have some understanding of how the
Security Content Automation Protocols work and be able to work with at least one
SCAP scanner software item.

External software requirements
------------------------------

The pmcs setup wouldn't be a "poor man" setup if we wouldn't leverage existing
infrastructure as much as possible.

* To build the SCAP data streams, we assume the administrator does this himself.
  This can be accomplished with tools such as open-scap.
* The first central repositories are simple HTTP directory structures; pmcs will
  provide a few scripts to easily manage those, such as creating the proper
  directory structure. 
* The target repository to save files in will, at first, be a simple CGI script
  to run on a web server. Authentication against the repositories is assumed to
  be handled using the system's server certificates if applicable.
* The pmcsa script (currently) relies on *curl*, *wget* and *nc* (netcat) on
  Unix to support its endeavors for network-related activities.

