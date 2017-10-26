#!/bin/bash

# Configuration

. ./config-demo-openshift-dotnet.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

# Additional Configuration
OPENSHIFT_APPLICATION_NAME=${OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT}

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_OUTPUT_FORMAT?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET?}
echo "OK"

echo "Setup .Net MusicStore Configuration_________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT           = ${OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET   = ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}"
echo "____________________________________________________________"

echo "Setup sample .Net sample application: ${OPENSHIFT_APPLICATION_NAME}"
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
 
oc new-app --name=${OPENSHIFT_APPLICATION_NAME} --template=dotnet-pgsql-persistent -l app=${OPENSHIFT_APPLICATION_NAME},phase=dev  || { echo "FAILED: Could not find or create the app=${OPENSHIFT_APPLICATION_NAME} " && exit 1; }
echo "		--> Follow the build logs with " && echo "oc logs bc/${OPENSHIFT_APPLICATION_NAME} --follow" 


#echo "	--> Waiting for the ${OPENSHIFT_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${OPENSHIFT_APPLICATION_NAME} | grep -v build | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
# immediately hit the application to trigger any lazy initialization
curl ${OPENSHIFT_APPLICATION_NAME}-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}

echo "	--> open web page"
firefox ${OPENSHIFT_APPLICATION_NAME}-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}

echo "Done."
