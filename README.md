test-basepack
=============

test base pack

```
$ bp-create --help
  --basepack <url> : url with branch or tag at the end
  --name <name>    : name of the basepack
  --help           : help

$ bp-create --baseback http@github.com/scheler/test-basepack.git#0.1  --name "First Basepack "

--> Retrieving baseback
--> Starting instance 
--> Installing packages
--> Creating AMI
--> Terminating instance

Basepack "First Basepack" successfully created - ami-i23sdf23

$ bp-create --baseback http@github.com/scheler/test-basepack.git#0.2  --name "Basepack second try"

--> Retrieving baseback
--> Starting instance 
--> Installing packages
--> Error
--> Terminating instance

Error log available in bp-create.log

$ bp-list 
ami-i23sdf23 First Basepack
ami-iasdf123 Basepack - v1.2
ami-i234asf2 Basepack - v1.3

$ bp-delete --ami ami-i23sdf23
ami-i23sdf23 deleted

$ 

```
