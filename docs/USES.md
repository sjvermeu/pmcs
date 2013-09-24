Use Cases
=========

This document gives a set of possible use cases for the pmcs infrastructure.

Inventory reporting
-------------------

Assume you want to keep track of (licensed) software across the organization. 

Start by asking the vendor(s) for the OVAL definitions for these products. Some
vendors will already provide such inventory checks, but if not you will find
many of these on various OVAL repositories.

Combine the OVAL inventory definitions for the products you want to report on in
a single OVAL file set (for instance, `inventory.xml`) under the proper class
(`stream/classes/windows/inventory.xml` if you want to report on Windows-running
products like SQL Server, Photoshop, etc.) It is not necessary to use this on a
class-level, but most OVAL tests are written for a particular class - make sure
to double-check the OVAL test you get.

```
~$ oval2xccdf.sh *oval.xml > inventory-xccdf.xml
~$ oscap ds sds-compose inventory-xccdf.xml inventory.xml
```

The `inventory.xml` is a SCAP data stream containing all the OVAL definitions
that were in the local working directory.

Now publish this `inventory.xml` file at `stream/classes/windows` and add the
following line to the `stream/classes/windows/list.conf` file:

```
oval#inventory#classes/windows/inventory.xml#
```

Upon the next scheduled run, the results of the inventory will be saved, per
system, as `inventory-oval-results.xml`.
