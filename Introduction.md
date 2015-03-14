# Introduction #

When looking for a simple way to access SOAP web services from my iPhone apps I found ... nothing. Well there are a couple of frameworks and toolkits out there but generally they

**require additinal libraries** are too bloated to be able to quickly use them
**are not making use of advantages of objective-C**

So I set out to build a mechanism which would allow me to quickly add SOAP support to my apps. When trying to come up with a good name I thought of SOUCH (like SOAP-Touch) or CoreSOAP. It became "Kernseife" which is the German translation of Core and Soap.

# Details #

To test the WSDL parser check out the project and call the resulting Kernseife binary providing a local WSDL file or an URL of one. This will create a .h and .m file in your current working directory. Add this plus all the files from the xml group in the SOAP project to your project.

To make a call all you need to do is instantiate the service with alloc/init and then call the methods described.


# To Do #

This is a work-in-progress. I am adding features and I am constantly making changes to add functionality that I require for my projects. So, for example, all the converting between XML data types and Cocoa data types is only done for a couple of types like strings.