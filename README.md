vagrant-osb1035
===============

Virtual machine for Virtualbox with Weblogic 10.3.5 - Oracle Service Bus 11g Release 1 (11.1.1.5.0) using vagrant and puppet
Based on https://github.com/biemond/biemond-wls-vagrant-soa-osb an modified to be able to install JDK6 and OSB 10.3.5.
Uses CentOS 6.5 (64 bits) with puppet 3.4.3.

Including orawls puppet modules by Edwin Biemond (https://github.com/biemond/biemond-orawls)

For OSB: download and add the following files to the /software folder:

* ofm_osb_generic_11.1.1.5.0_disk1_1of1.zip (http://download.oracle.com/otn/nt/middleware/11g/111150/ofm_osb_generic_11.1.1.5.0_disk1_1of1.zip)
* wls1035_generic.jar (http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html)
* jdk-6u45-linux-x64.bin (http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase6-419409.html)

For developing OSB projects using OEPE (Oracle Enterprise Pack for Eclipse), version 11.1.1.7.2 is compatible with this (older) release of Oracle Service Bus.
