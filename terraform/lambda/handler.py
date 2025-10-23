"""
Lambda Function Handler for Serverless API Backend

This Lambda function provides two main functionalities:
1. Extracts and returns visitor location information from CloudFront headers
2. Queries CloudWatch Logs to retrieve WAF blocked request counts

Environment Variables:
    WAF_LOG_GROUP_NAME: Name of the CloudWatch Log Group containing WAF logs
"""

import json
import os
import time
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

import boto3

# WAF logs for CloudFront are always in us-east-1.
# We must explicitly create the client in that region.
logs_client = boto3.client("logs", region_name="us-east-1")

# Get the WAF log group name from environment variables
WAF_LOG_GROUP_NAME: str = os.environ.get("WAF_LOG_GROUP_NAME", "")


def get_cors_headers() -> Dict[str, str]:
    """
    Returns standard CORS headers to be included in all responses.

    Returns:
        Dictionary of CORS headers
    """
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Methods": "GET,OPTIONS",
    }


def get_visitor_location(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extracts visitor location information from CloudFront headers.

    CloudFront automatically adds geographic information to requests
    based on the viewer's IP address.

    Args:
        event: The Lambda event object containing request headers

    Returns:
        A dictionary containing the HTTP response with location data including:
        - city: Viewer's city
        - region: Viewer's region, state, or province (e.g., ON, CA, NY)
        - edgeLocation: CloudFront edge location serving the request
    """
    headers = event.get("headers", {})

    # CloudFront headers that provide geo-location info
    # NOTE: Header names are converted to lowercase by API Gateway
    city = headers.get("cloudfront-viewer-city", "Unknown")
    # This header provides the region/state/province code
    region = headers.get("cloudfront-viewer-country-region", "Unknown")
    edge_location = headers.get("x-amz-cf-pop", "Unknown")

    return {
        "statusCode": 200,
        "headers": get_cors_headers(),
        "body": json.dumps(
            {
                "city": city,
                "region": region,
                "edgeLocation": edge_location,
            }
        ),
    }


def get_waf_block_count(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Queries CloudWatch Logs to count blocked requests by WAF in the last hour.

    Uses CloudWatch Logs Insights to query WAF logs and count how many
    requests were blocked in the past 60 minutes.

    Args:
        event: The Lambda event object (unused but required for handler compatibility)

    Returns:
        A dictionary containing the HTTP response with block count data

    Raises:
        Returns 500 status code if WAF log group is not configured or query fails
    """
    # Validate WAF log group configuration
    if not WAF_LOG_GROUP_NAME:
        return {
            "statusCode": 500,
            "headers": get_cors_headers(),
            "body": json.dumps({"error": "WAF log group name not configured."}),
        }

    # Define time range for query (last hour)
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)

    # CloudWatch Logs Insights query to count blocked requests
    query = """
    fields @timestamp, httpRequest.clientIp, action
    | filter action = 'BLOCK'
    | stats count(*) as blockCount
    """

    try:
        # Start the CloudWatch Logs Insights query
        start_query_response = logs_client.start_query(
            logGroupName=WAF_LOG_GROUP_NAME,
            startTime=int(start_time.timestamp()),
            endTime=int(end_time.timestamp()),
            queryString=query,
        )

        query_id = start_query_response["queryId"]

        # Poll for query completion
        response: Optional[Dict[str, Any]] = None
        status = "Running"

        while status in ["Running", "Scheduled"]:
            time.sleep(1)
            response = logs_client.get_query_results(queryId=query_id)
            status = response["status"]

        # Extract block count from query results
        block_count = 0
        if response and response["status"] == "Complete" and response["results"]:
            # The result is a list of lists of dicts
            # Example: [[{'field': 'blockCount', 'value': '123'}]]
            result_field = response["results"][0]
            count_entry = next(
                (item for item in result_field if item["field"] == "blockCount"), None
            )
            if count_entry:
                block_count = int(count_entry["value"])

        return {
            "statusCode": 200,
            "headers": get_cors_headers(),
            "body": json.dumps({"blockCount": block_count}),
        }

    except Exception as e:
        print(f"Error querying WAF logs: {e}")
        return {
            "statusCode": 500,
            "headers": get_cors_headers(),
            "body": json.dumps(
                {"error": "Failed to query WAF logs.", "details": str(e)}
            ),
        }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler that routes requests based on the 'action' query parameter.

    Supported actions:
    - 'location': Returns visitor location information from CloudFront headers
    - 'waf': Returns count of blocked requests in the last hour

    Args:
        event: The Lambda event object containing request information
        context: The Lambda context object (unused)

    Returns:
        A dictionary containing the HTTP response

    Example:
        GET /default/getVisitorLocation?action=location
        GET /default/getVisitorLocation?action=waf
    """
    # Extract action parameter from query string
    query_params = event.get("queryStringParameters", {}) or {}
    action = query_params.get("action")

    if action == "location":
        return get_visitor_location(event)
    elif action == "waf":
        return get_waf_block_count(event)
    else:
        # Return error for missing or invalid action parameter
        return {
            "statusCode": 400,
            "headers": get_cors_headers(),
            "body": json.dumps(
                {
                    "error": "Missing or invalid action parameter.",
                    "validActions": ["location", "waf"],
                }
            ),
        }
