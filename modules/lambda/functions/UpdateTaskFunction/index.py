import json
import os
from datetime import datetime, UTC

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

        body = json.loads(event.get("body", "{}"))

        title = body.get("title")
        status = body.get("status")

        if not title and not status:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": "Nothing to update"
                })
            }

        if status and status not in ["pending", "done"]:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": "status must be pending or done"
                })
            }

        update_expression_parts = []
        expression_attribute_values = {}

        if title:
            update_expression_parts.append("title = :title")
            expression_attribute_values[":title"] = title

        if status:
            update_expression_parts.append("#s = :status")
            expression_attribute_values[":status"] = status

        update_expression_parts.append("updatedAt = :updatedAt")
        expression_attribute_values[":updatedAt"] = datetime.now(UTC).isoformat()

        update_expression = "SET " + ", ".join(update_expression_parts)

        response = table.update_item(
            Key={
                "id": task_id
            },
            UpdateExpression=update_expression,
            ExpressionAttributeNames={
                "#s": "status"
            },
            ExpressionAttributeValues=expression_attribute_values,
            ConditionExpression="attribute_exists(id)",
            ReturnValues="ALL_NEW"
        )

        updated_task = response["Attributes"]

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(updated_task)
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