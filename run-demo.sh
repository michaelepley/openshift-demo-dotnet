#!/bin/bash

# Configuration

. ./config-demo-openshift-dotnet.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET?}
echo "OK"
echo "Setup PHP Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET   = ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}"
echo "____________________________________________________________"

echo "Running openshift Dot Net demo"

echo "	--> Logging into openshift"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}
echo "	--> Setting up simple example applications"
. ./setup-dotnetsampleapp.sh
echo "		--> press enter to continue" && read
echo "	--> Setting up a more complex 3 tier MVC application with a postgresql database backend"
. ./clean.sh
echo "	--> Waiting for the previous demo components to be cleaned up; press enter to cancel"
while oc get projects | grep ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

. ./setup-dotnetsample-musicstore.sh
echo "		--> press enter to continue" && read
echo "	--> use clean.sh to cleanup"
echo "Done."
