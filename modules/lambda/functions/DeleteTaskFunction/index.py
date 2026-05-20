import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TASKS_TABLE"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    try:
        path_params = event.get("pathParameters") or {}

        task_id = path_params.get("id")

        if not task_id:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": "Task id is required"
                })
            }

        table.delete_item(
            Key={
                "id": task_id
            },
            ConditionExpression="attribute_exists(id)"
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Task deleted successfully"
            })
        }

    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return {
            "statusCode": 404,
            "body": json.dumps({
                "message": "Task not found"
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }