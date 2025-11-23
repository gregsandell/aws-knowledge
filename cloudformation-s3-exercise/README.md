# Create an S3 Bucket with a CloudFormation Template

## Source of exercise
The following google prompt:
>simple exercise to learn how to use AWS cloudformation

...came back with an AI reply which appears in the Instructions below.

This all worked for me.  GJS 2025-11-20

## Instructions
A simple exercise is to create an Amazon S3 bucket using CloudFormation. 

Start by writing a basic template in YAML or JSON to define an AWS::S3::Bucket resource, then use the AWS Management Console or AWS CLI to create a stack from this template. 

This process introduces you to defining resources in a template, deploying them as a stack, and verifying the result in the AWS console.

### Step 1: Create a CloudFormation template

1. Choose a template format: Use YAML, which is generally easier to read and write than JSON.
1. Define the structure: Include a Resources section.
1. Add your resource: Within Resources, define a logical ID for your S3 bucket (e.g., MyS3Bucket) and specify its type as AWS::S3::Bucket.

Example (YAML):
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: A simple template to create an S3 bucket.
Resources:
  MyS3Bucket:
    Type: AWS::S3::Bucket
```
(Optional) Add a logical ID: If you need to name the bucket, you can add a BucketName property. If you don't, AWS will generate a name for you.
```yaml
MyS3Bucket:
Type: AWS::S3::Bucket
Properties:
BucketName: my-unique-bucket-name-12345
```

### Step 2: Deploy the stack

1. Go to the AWS CloudFormation console.
1. Select "Create stack" and choose "With new resources (standard)".
1. Upload your template: Choose "Upload a template file" and select the YAML file you just created.
1. Click "Next" and provide a stack name.
1. Click "Next" again and then "Create stack".

### Step 3: Verify your resources

1. After the stack creation is complete, click on the "Resources" tab.
1. Find the S3 bucket: You will see the logical ID (MyS3Bucket) and a link to the physical S3 bucket that was created.
1. Click the link to go to the Amazon S3 console and see your new bucket.

### Step 4: Clean up
1. In the CloudFormation console, select your stack.
1. Click "Delete" to remove the stack and all associated resources, including the S3 bucket. 
