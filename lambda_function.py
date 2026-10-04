import json
import boto3

# Initialize the DynamoDB client
dynamodb = boto3.resource('dynamodb')
# This must match the exact name of your DynamoDB table in Terraform
table = dynamodb.Table('cloud-resume-challenge-table')

def lambda_handler(event, context):
    try:
        # Atomically increment the visitor count by 1
        response = table.update_item(
            Key={'id': 'visitors'},
            UpdateExpression='ADD quantity :inc',
            ExpressionAttributeValues={':inc': 1},
            ReturnValues='UPDATED_NEW'
        )
        
        # Extract the updated count from the response
        visitor_count = int(response['Attributes']['quantity'])
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*', # Crucial for CORS
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            'body': json.dumps({'count': visitor_count})
        }
        
    except Exception as e:
        print(f"Error updating visitor count: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Could not update visitor count'})
        }