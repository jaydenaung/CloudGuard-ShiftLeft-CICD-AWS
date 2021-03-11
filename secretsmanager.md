# Storing Credentials in AWS Secrets Manager

You can securely store CloudGuard API key and API secrets in AWS Secrets Manager in order to avoid embedding them in plain text. Codebuild can make API call and retrieve the API key and secrets when building scanning container image. 

1. Create secrets  in secret manager

Execute the following commands to create two secret strings called "CHKP_CLOUDGUARD_ID" and "CHKP_CLOUDGUARD_SECRET". Replace the value with CloudGuard API keys and secrets that you've generated on CloudGuard portal.

```bash
# Store CloudGuard API Key in Secrets Manager

aws secretsmanager create-secret --name CHKP_CLOUDGUARD_ID --secret-string abcd1234

# Store CloudGuard API Secret in AWS Secrets Manager

aws secretsmanager create-secret --name CHKP_CLOUDGUARD_SECRET --secret-string 67890xyz

```


2. Test retrieving the secret for the CloudGuard API key

Execute the following command;

```bash
aws secretsmanager get-secret-value --secret-id CHKP_CLOUDGUARD_ID | jq -r '.SecretString'
```

**Expected output**

```
abcd1234
```

3. Export variables in [buildspec.yml](buildspec.yml)

Then you'll need to export the commands in the [buildspec.yml](buildspec.yml) as variables. CloudGuard will use the API key and secrets stored in the AWS Secrets Manager when running assessments. 

```
export CHKP_CLOUDGUARD_ID=$(aws secretsmanager get-secret-value --secret-id cloudguard-api-1 | jq -r '.SecretString')

export CHKP_CLOUDGUARD_SECRET=$(aws secretsmanager get-secret-value --secret-id cloudguard-api-secret | jq -r '.SecretString')

```
--- 
## Conclusion 

Not storing any credentials in clear text is one of the DevSecOps best practices. When using CodeBuild, you can use either AWS SSM or Secrets Manager to store your credentials required by security scanning tools. 