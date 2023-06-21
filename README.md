<p  align="center">
<img src="https://www.keyvalue.systems/logo.png" width="290" height="100">
</p>

# ECR Image Scanning GitHub Action
This GitHub Action automatically scans an ECR (Elastic Container Registry) image when it is pushed to the repository. It utilizes the AWS CLI and ECR scanning capabilities to perform the scan and provide a scan report.

## Pre-requisites

To use this action, ensure that you have the AWS CLI installed and properly configured in your runner environment.IAM permissions required for this action:

 * ecr:DescribeImageScanFindings
 * ecr:StartImageScan

Also ensure that scan on push is disabled on the repository.

## Description

This action utilizes a shell script executed within a Docker container to identify critical and high-level vulnerabilities linked to an image being pushed to the ECR repository.
## Usage
```
name: Push to ECR

on:
  pull_request:
    branches:
      - main
jobs:
  Build-Push-Scan-Image:
    runs-on: ubuntu-latest 
    steps:
    - name: Scan Docker image
      id: docker-scan
      uses: KeyValueSoftwareSystems/action-ecr-image-scan@main
      env:
        ECR_REPOSITORY: ${{ env.ECR_REPOSITORY }}
        IMAGE_TAG:  	${{ github.sha }}
      with:
        ecr_repository: ${{ env.ECR_REPOSITORY }}
        image_tag: ${{ env.IMAGE_TAG }}
        pr_comment: true
        github_token: ${{ secrets.GITHUB_TOKEN }} 
        url: ${{ github.event.pull_request.comments_url }}
        aws_region: ap-south-1    
    - name: Fail workflow if vulnerabilities found
      env:
        vulnerability: ${{ steps.docker-scan.outputs.VULNERABILITY }}  
        block_build_on_failure: true               
      run:  | 
        if [ "${{env.block_build_on_failure }}" = true && "${{ env.vulnerability }}" = true ]; then
        exit 1
        fi
```
## Input

| Input  | Required? | Description |
| ------ | --------- | ----------- |
| ecr_repository | Yes  | The name of your ECR repository |
| image_tag    | Yes | Tag of the image being pushed|
| aws_region | Yes | AWS region of the repository|
| pr_comment | Yes | true/false |
|github_token| No |For updating th PR comment with scan result|
|url| No |URL for calling the POST request to update PR|


## Output

After the scan is completed, this action will produce the scan results and provide a link to the scan report. The scan report and the detailed report URL in the AWS console will be included as comments in the pull request and displayed in the GitHub step summary for easy access and visibility.
### Parameters passed as output :
     

| Output  | Value | Description |
| ------ | --------- | ----------- |
| VULNERABILITY | true/false | Whether vulnerabilities are found or not |

## Sample Output
#### Github PR comment
![Github PR Comment](outputs/github-pr-output.png)

#### Github Summary Report
![Github Summary](outputs/github-summary-output.png)
