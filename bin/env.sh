#!/bin/bash

# The spec suite connects to the LimeSurvey RemoteControl API. If you intend to run the
# specs, update this script with values specific to your situation. Then run this script
# to set up your environment prior to running the specs.
# Note that the specs test accessing a survey by id. Kindly provide that id below. If
# necessary, create a dummy survey for this purpose. It only has to exist and be activated.

# If you are not going to run the specs, you can skip this.

echo "Setting LimeSurvey API auth"

LIMESURVEY_ENDPOINT="https://<your_domain>.limequery.com/admin/remotecontrol"
LIMESURVEY_ACCOUNT="margarita"
LIMESURVEY_PASSWORD="sooper_seekrit"
LIMESURVEY_SURVEY_ID=<the id of one of your surveys>

export LIMESURVEY_ENDPOINT
export LIMESURVEY_ACCOUNT
export LIMESURVEY_PASSWORD
export LIMESURVEY_SURVEY_ID
