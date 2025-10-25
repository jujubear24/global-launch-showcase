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
        - country: Viewer's country code
        - edgeLocation: CloudFront edge location identifier from X-Amz-Cf-Id
    """
    headers = event.get("headers", {})

    # DEBUG LOGGING: Print all headers received
    print("=" * 80)
    print("DEBUG: All headers received by Lambda:")
    print(json.dumps(headers, indent=2))
    print("=" * 80)

    # CloudFront headers that provide geo-location info
    # NOTE: Header names are converted to lowercase by API Gateway
    city: str = headers.get("cloudfront-viewer-city", "Unknown")
    # This header provides the region/state/province code
    region: str = headers.get("cloudfront-viewer-country-region", "Unknown")
    # Country code (e.g., CA, US)
    country: str = headers.get("cloudfront-viewer-country", "Unknown")
    # Edge location identifier - extracted from X-Amz-Cf-Id header
    # This contains the POP (Point of Presence) code in the format: XXXXX-YYYYY
    cf_id: str = headers.get("x-amz-cf-id", "Unknown")
    edge_location: str = cf_id.split("-")[0] if cf_id != "Unknown" else "Unknown"

    # DEBUG LOGGING: Print extracted values
    print("DEBUG: Extracted location values:")
    print(f"  City: {city}")
    print(f"  Region: {region}")
    print(f"  Country: {country}")
    print(f"  CF-ID (full): {cf_id}")
    print(f"  Edge Location (POP): {edge_location}")
    print("=" * 80)

    return {
        "statusCode": 200,
        "headers": get_cors_headers(),
        "body": json.dumps(
            {
                "city": city,
                "region": region,
                "country": country,
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
    # DEBUG LOGGING: Check WAF configuration
    print("=" * 80)
    print(f"DEBUG: WAF_LOG_GROUP_NAME = {WAF_LOG_GROUP_NAME}")
    print("=" * 80)

    # Validate WAF log group configuration
    if not WAF_LOG_GROUP_NAME:
        print("ERROR: WAF log group name not configured!")
        return {
            "statusCode": 500,
            "headers": get_cors_headers(),
            "body": json.dumps({"error": "WAF log group name not configured."}),
        }

    # Define time range for query (last hour)
    end_time: datetime = datetime.utcnow()
    start_time: datetime = end_time - timedelta(hours=1)

    # CloudWatch Logs Insights query to count blocked requests
    query: str = """
    fields @timestamp, httpRequest.clientIp, action
    | filter action = 'BLOCK'
    | stats count(*) as blockCount
    """

    print(f"DEBUG: Starting WAF query from {start_time} to {end_time}")

    try:
        # Start the CloudWatch Logs Insights query
        start_query_response: Dict[str, Any] = logs_client.start_query(
            logGroupName=WAF_LOG_GROUP_NAME,
            startTime=int(start_time.timestamp()),
            endTime=int(end_time.timestamp()),
            queryString=query,
        )

        query_id: str = start_query_response["queryId"]
        print(f"DEBUG: Query started with ID: {query_id}")

        # Poll for query completion
        response: Optional[Dict[str, Any]] = None
        status: str = "Running"
        poll_count: int = 0

        while status in ["Running", "Scheduled"]:
            time.sleep(1)
            poll_count += 1
            response = logs_client.get_query_results(queryId=query_id)
            status = response["status"]
            print(f"DEBUG: Poll #{poll_count} - Query status: {status}")

        print(
            f"DEBUG: Query completed. Response: {json.dumps(response, indent=2, default=str)}"
        )

        # Extract block count from query results
        block_count: int = 0
        if response and response["status"] == "Complete" and response["results"]:
            # The result is a list of lists of dicts
            # Example: [[{'field': 'blockCount', 'value': '123'}]]
            result_field: list = response["results"][0]
            print(f"DEBUG: Result field: {json.dumps(result_field, indent=2)}")

            count_entry: Optional[Dict[str, str]] = next(
                (item for item in result_field if item["field"] == "blockCount"), None
            )
            if count_entry:
                block_count = int(count_entry["value"])
                print(f"DEBUG: Block count extracted: {block_count}")
            else:
                print("DEBUG: 'blockCount' field not found in results")
        else:
            print(
                f"DEBUG: Query did not complete successfully. Status: {response['status'] if response else 'None'}"
            )

        print("=" * 80)

        return {
            "statusCode": 200,
            "headers": get_cors_headers(),
            "body": json.dumps({"blockCount": block_count}),
        }

    except Exception as e:
        print(f"ERROR querying WAF logs: {e}")
        print("=" * 80)
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
    # DEBUG LOGGING: Print entire event
    print("=" * 80)
    print("DEBUG: Full Lambda event:")
    print(json.dumps(event, indent=2, default=str))
    print("=" * 80)

    # Extract action parameter from query string
    query_params: Dict[str, str] = event.get("queryStringParameters", {}) or {}
    action: Optional[str] = query_params.get("action")

    print(f"DEBUG: Action requested: {action}")

    if action == "location":
        return get_visitor_location(event)
    elif action == "waf":
        return get_waf_block_count(event)
    else:
        # Return error for missing or invalid action parameter
        print(f"ERROR: Invalid action '{action}'")
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
