#!/usr/bin/env bash
set -e
REPO_NAME=$INPUT_ECR_REPOSITORY
IMAGE_TAG=$INPUT_IMAGE_TAG
URL=$INPUT_URL
GITHUB_TOKEN=$INPUT_GITHUB_TOKEN
PR_COMMENT=$INPUT_PR_COMMENT
REGION=$INPUT_AWS_REGION

aws configure list >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    aws ecr start-image-scan --repository-name $REPO_NAME --image-id imageTag=$IMAGE_TAG
    aws ecr wait image-scan-complete --repository-name $REPO_NAME --image-id imageTag=$IMAGE_TAG
    if [ $(echo $?) -eq 0 ]; then
        SCAN_FINDINGS=$(aws ecr describe-image-scan-findings --repository-name $REPO_NAME --image-id imageTag=$IMAGE_TAG | jq '.imageScanFindings.findingSeverityCounts')
        CRITICAL=$(echo $SCAN_FINDINGS | jq '.CRITICAL // 0')
        HIGH=$(echo $SCAN_FINDINGS | jq '.HIGH // 0')

        ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
        IMAGE_DIGEST=$(aws ecr describe-images --repository-name $REPO_NAME --image-ids imageTag=$IMAGE_TAG --query 'imageDetails[].imageDigest' --output text)
        REPORT_URL="$(echo "https://$REGION.console.aws.amazon.com/ecr/repositories/private/$ACCOUNT_ID/$REPO_NAME/_/image/$IMAGE_DIGEST/scan-results?region=$REGION")"
        SCAN_RESULT="$(echo "Found $CRITICAL CRITICAL and $HIGH HIGH level vulnerabilities in Docker image")"

        if [[ $PR_COMMENT == true ]]; then
         curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GITHUB_TOKEN" "$URL" -d "{ \"body\": \"Docker Image Scan Output \\n >$SCAN_RESULT \\n For detailed scan report <a href=\\\"$REPORT_URL\\\"> Click here </a>\" }"
        fi
        
        if [[  $CRITICAL != 0 || $HIGH != 0 ]]; then
            VULNERABILITY=true
        else 
            VULNERABILITY=false 
        fi
    fi
    HYPERLINK_URL="[Click here]($REPORT_URL)"
    echo "VULNERABILITY=$VULNERABILITY" >> $GITHUB_OUTPUT
    echo "$SCAN_RESULT" >> $GITHUB_STEP_SUMMARY    
    echo "Detailed Scan Report - $HYPERLINK_URL" >> $GITHUB_STEP_SUMMARY  
  
else
    echo "AWS CLI is not configured."
    exit 1
fi



