# Container Image Access

Currents container images are hosted in a private AWS ECR registry. You'll need to set up access and pull/mirror the images before running the services.

## 1. Create an IAM Role for ECR Access

Create an IAM role in your AWS account with the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": [
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/api/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/api",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/change-streams/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/change-streams",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/director/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/director",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/scheduler/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/scheduler",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/writer/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/writer",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/webhooks/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/webhooks"
      ]
    }
  ]
}
```

## 2. Share Your Role ARN with Currents

Send the ARN of the IAM role you created to your Currents contact. They will configure cross-account access to allow your role to pull images.

## 3. Authenticate with ECR

Once access is granted, authenticate Docker with the Currents ECR registry:

```bash
# Assume the role (replace with your role ARN)
aws sts assume-role --role-arn <YOUR_ROLE_ARN> --role-session-name currents-access

# Export the temporary credentials from the response
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# Log in to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 513558712013.dkr.ecr.us-east-1.amazonaws.com
```

## 4. Mirror Images to Your Registry (Recommended)

Since ECR credentials expire and your deployment environment may not have AWS access, we recommend mirroring images to your own container registry:

```bash
# Define source and destination
SOURCE_REGISTRY=513558712013.dkr.ecr.us-east-1.amazonaws.com/currents/on-prem
TARGET_REGISTRY=your-registry.example.com/currents
TAG=staging  # or specific version tag

# List of Currents services
SERVICES="api director change-streams scheduler writer webhooks"

# Pull, tag, and push each image
for service in $SERVICES; do
  docker pull ${SOURCE_REGISTRY}/${service}:${TAG}
  docker tag ${SOURCE_REGISTRY}/${service}:${TAG} ${TARGET_REGISTRY}/${service}:${TAG}
  docker push ${TARGET_REGISTRY}/${service}:${TAG}
done
```

## 5. Configure Docker Compose

Update your `.env` file to use your mirrored images:

```bash
# Point to your registry (include trailing slash)
DC_CURRENTS_IMAGE_REPOSITORY=your-registry.example.com/currents/

# Specify the image tag
DC_CURRENTS_IMAGE_TAG=staging
```

If pulling directly from Currents ECR (not recommended for production):

```bash
DC_CURRENTS_IMAGE_REPOSITORY=513558712013.dkr.ecr.us-east-1.amazonaws.com/currents/on-prem/
DC_CURRENTS_IMAGE_TAG=staging
```

> **Note:** When pulling directly from ECR, you'll need to re-authenticate periodically as credentials expire after 12 hours. Mirroring to your own registry avoids this operational overhead.

## Next Steps

Once you have access to the container images, continue with the [Quickstart Guide](./quickstart.md).
