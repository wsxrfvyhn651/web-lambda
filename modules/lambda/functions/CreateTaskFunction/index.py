import json
import os
import uuid
from datetime import datetime, UTC

import boto3

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TASKS_TABLE"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))

        user_id = body.get("userId")
        title = body.get("title")

        if not user_id or not title:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": "userId and title are required"
                })
            }

        task = {
            "id": str(uuid.uuid4()),
            "userId": user_id,
            "title": title,
            "status": "pending",
            "createdAt": datetime.now(UTC).isoformat()
        }

        table.put_item(Item=task)

        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(task)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }