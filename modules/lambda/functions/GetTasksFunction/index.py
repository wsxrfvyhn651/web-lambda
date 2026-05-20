import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TABLE_NAME"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    try:
        # lấy userId từ query string
        # GET /tasks?userId=user-123
        query_params = event.get("queryStringParameters") or {}

        user_id = query_params.get("userId")

        if not user_id:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": "userId is required"
                })
            }

        response = table.query(
            IndexName="userId-index",
            KeyConditionExpression=Key("userId").eq(user_id)
        )

        tasks = response.get("Items", [])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(tasks)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }