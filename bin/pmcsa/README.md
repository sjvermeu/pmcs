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
