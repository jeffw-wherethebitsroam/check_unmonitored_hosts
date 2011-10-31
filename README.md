Check Unmonitored Hosts
=======================

Scans the given subnet for hosts and checks to make sure that all hosts discovered appear in the opsview database.

Requirements
------------

These requirements should probably exist by default on most opsview installs

- Fping
- Perl with DBI
- Connection details for your opsview database

Configuration
-------------

The best way to set this up is to add an Unmonitored Host check to your opsview server with the arguments:

-w 0 -c 5 %SUBNET%

Then, for each opsview host, apply the check and under the attributes for the host, add a SUBNET attribute for each subnet you want checked