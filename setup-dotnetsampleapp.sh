#!/bin/bash

# Configuration

. ./config-demo-openshift-dotnet.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_OUTPUT_FORMAT?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET?}
echo "OK"
echo "Setup PHP Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET   = ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}"
echo "____________________________________________________________"


echo "Setup sample dot net core 1.0 application"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Verify the openshift cluster is working normally"
oc status -v || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; }
echo "	--> Verify openshift has the necessary prerequisites installed"
echo "		--> Verify the dot net core imagestreams are available"
[ `oc get -n openshift is | grep dotnet | wc -l` == 1 ] || { echo "FAILED: Could not verify the presence of the required dot net image streams. Please install or contact your system administrator" && exit 1; }
echo "		--> Verify the dot net core sample application templates are available, or attempt to load these"
[ `oc get -n openshift templates | grep dotnet | wc -l` == 2 ] || { echo "FAILED: Could not verify the presence of the required dot net templates. Please install or contact your system administrator" && exit 1; }


echo "	--> Create a new application from the dotnetcore10 template and application git repo"
 
oc get dc/dotnet-example-1 || oc new-app --name=dotnet-example-1 registry.access.redhat.com/dotnet/dotnetcore-10-rhel7~https://github.com/redhat-developer/s2i-dotnetcore-ex#dotnetcore-1.0 --context-dir=app -l app=${OPENSHIFT_APPLICATION_NAME},part=example-1 || { echo "FAILED: Could not find or create the app=${OPENSHIFT_APPLICATION_NAME},part=example-1 " && exit 1; }
#oc get dc/php || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git --name=php -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend -o ${OPENSHIFT_OUTPUT_FORMAT} > ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT} || { echo "FAILED: Could not find or create the app=${OPENSHIFT_APPLICATION_NAME},part=frontend " && exit 1; }
#oc create -f ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT} || { echo "FAILED: Could not find or create app=${OPENSHIFT_APPLICATION_NAME},part=frontend" && exit 1; } 
#oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "requests" : { "cpu" : "400m" } } } ] } } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=frontend to set resource limits" && exit 1; }
#oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "limits" : { "cpu" : "500m" } } } ] } } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=frontend to set resource limits" && exit 1; }
echo "		--> Follow the build logs with " && echo "oc logs bc/dotnet-example-1 --follow" 

echo "	--> ensure the application is routable"
oc get route dotnet-example-1 || oc expose service dotnet-example-1 || { echo "FAILED: Could not verify route to app=${OPENSHIFT_APPLICATION_NAME},part=example-1" && exit 1; }

echo "	--> Waiting for the ${OPENSHIFT_APPLICATION_FRONTEND_NAME} application to start....press any key to proceed"
while ! oc get pods | grep dotnet-example-1 | grep -v build | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
# immediately hit the application to trigger any lazy initialization
curl dotnet-example-1-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}

echo "press enter to continue" && read
echo "	--> Create a new application from the dotnetcore11 template and application git repo"
oc get dc/dotnet-example-2 || oc new-app --name=dotnet-example-2 registry.access.redhat.com/dotnet/dotnetcore-11-rhel7~https://github.com/redhat-developer/s2i-dotnetcore-ex#dotnetcore-1.1 --context-dir=app -l app=${OPENSHIFT_APPLICATION_NAME},part=example-2 || { echo "FAILED: Could not find or create the app=${OPENSHIFT_APPLICATION_NAME},part=example-2 " && exit 1; }
echo "		--> Follow the build logs with " && echo "oc logs bc/dotnet-example-2 --follow" 
echo "	--> ensure the application is routable"
oc get route dotnet-example-2 || oc expose service dotnet-example-2 || { echo "FAILED: Could not verify route to app=${OPENSHIFT_APPLICATION_NAME},part=example-2" && exit 1; }

echo "	--> Waiting for the ${OPENSHIFT_APPLICATION_FRONTEND_NAME} application to start....press any key to proceed"
while ! oc get pods | grep dotnet-example-2 | grep -v build | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
# immediately hit the application to trigger any lazy initialization
curl dotnet-example-2-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}

echo "	--> open web page"
firefox dotnet-example-1-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}
firefox dotnet-example-2-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}

echo "Done."
