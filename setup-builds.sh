#!/bin/bash

# Configuration

. ./config-demo-openshift-dotnet.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

# Additional Configuration
OPENSHIFT_APPLICATION_NAME=${OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT}

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET?}
echo "OK"

echo "Setup Dot Net MusicStore Build Demo Configuration_________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT           = ${OPENSHIFT_APPLICATION_NAME_DOTNETCORESAMPLE_MUSICSTORE_DEFAULT}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET   = ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}"
echo "____________________________________________________________"

echo "Setup sample build pipeline for .Net ${OPENSHIFT_APPLICATION_NAME} application"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Make sure that jenkins is set up first"
echo "		--> OCP build pipelines are managed via a jenkins server deployed in the project"
# oc get dc/jenkins || oc process openshift//jenkins-ephemeral -l app=${OPENSHIFT_APPLICATION_NAME},part=cicd JENKINS_PASSWORD=password | oc create -f - || { echo "FAILED: Could not create Jenkins CICD server" && exit 1; }
oc get dc/jenkins || oc process openshift//jenkins-ephemeral -l app=${OPENSHIFT_APPLICATION_NAME},part=cicd | oc create -f - || { echo "FAILED: Could not create Jenkins CICD server" && exit 1; }
echo "	--> Waiting for jenkins pods to start"
sleep 2s
for COUNT in {1..45} ; do curl -s "http://jenkins-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}/login?from=%2F" && break; echo -n "." && sleep 1s; done; echo ""
echo "		--> press enter to continue" && read
echo "	--> Creating Jenkins build pipeline for the ${OPENSHIFT_APPLICATION_NAME}"
oc get bc/${OPENSHIFT_APPLICATION_NAME}-build-pipeline || echo '{ "apiVersion": "v1", "kind": "BuildConfig", "metadata": { "name": "'${OPENSHIFT_APPLICATION_NAME}'-build-pipeline", "labels": { "app": "'${OPENSHIFT_APPLICATION_NAME}'", "part": "build" }, "annotations": { "pipeline.alpha.openshift.io/uses": "[{\"name\": \"'${OPENSHIFT_APPLICATION_NAME}'\", \"namespace\": \"\", \"kind\": \"DeploymentConfig\"}]" } }, "spec": { "runPolicy": "Serial", "strategy": { "type": "Source", "jenkinsPipelineStrategy": { "jenkinsfile": "node('\''maven'\'') {\n  stage '\''build'\''\n  openshiftBuild(buildConfig: '\''musicstore'\'', showBuildLogs: '\''true'\'')\nstage '\''deploy'\''\n  openshiftDeploy(deploymentConfig: '\''musicstore'\'')\n  openshiftScale(deploymentConfig: '\''musicstore'\'',replicaCount: '\''2'\'')\n}" } }, "output": {}, "resources": {} } }' | oc create -f - || { echo "FAILED: could not find or create build pipeline definition" && exit 1; }

echo "		--> press enter to continue" && read

echo "	--> Trigger a build using the pipeline"
oc start-build bc/musicstore-build-pipeline || { echo "FAILED: Could not start build pipeline" && exit 1; }
echo "		--> press enter to continue" && read

echo "	--> TODO: Add a github webhook to trigger the build"



echo "	--> open web browser"
echo "		--> the php build pipelines status should be shown; at least one build should be shown in it"
firefox https://jenkins-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}/
echo "		--> on php build pipelines status page, select the most recent and this should show a detailed log of its activities, including the delegation to the openshift builder, the deployment, and the scaling of the application"
firefox https://jenkins-${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}.${OPENSHIFT_APPS}/job/${${OPENSHIFT_PROJECT_PRIMARY_DEMO_DOTNET}-${OPENSHIFT_APPLICATION_NAME}-build-pipeline/

echo "Done"

