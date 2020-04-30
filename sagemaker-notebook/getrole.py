import os
from pathlib import Path


def get_sm_execution_role() -> str:
    if Path("/home/ec2-user/SageMaker").is_dir():
        # Probably on SageMaker notebook instance.
        import sagemaker

        return sagemaker.get_execution_role()
    else:
        # Unlikely on SageMaker notebook instance.
        # cf - https://github.com/aws/sagemaker-python-sdk/issues/300

        # Rely on botocore rather than boto3for this function, to minimize
        # dependency on some environments where botocore exists, but not boto3.
        import botocore.session

        client = botocore.session.get_session().create_client("iam")
        response_roles = client.list_roles(
            PathPrefix="/",
            # Marker='string',
            MaxItems=999,
        )
        for role in response_roles["Roles"]:
            if role["RoleName"].startswith("AmazonSageMaker-ExecutionRole-"):
                # print('Resolved SageMaker IAM Role to: ' + str(role))
                return role["Arn"]
        raise Exception(
            "Could not resolve what should be the SageMaker role to be used"
        )
