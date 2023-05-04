from dotenv import load_dotenv
load_dotenv()
import os
import requests
from dateutil.parser import parse
import statistics
import sys

experiment_id = int(sys.argv[1])

# Set up Azure Monitor Query API
tenant_id = os.environ['TENANT_ID']
client_id = os.environ['CLIENT_ID']
client_secret = os.environ['CLIENT_SECRET']
subscription_id = os.environ['SUBSCRIPTION_ID']
resource_group = os.environ['RESOURCE_GROUP']
resource_name = os.environ['RESOURCE_NAME']
workspace_id = os.environ['WORKSPACE_ID']

# Get access token
url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/token'
data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'resource': 'https://management.azure.com/'
}
response = requests.post(url, data=data)
access_token = response.json()['access_token']

# Query logs from Application Insights
query = '''
let MessageSent = AppInsights
| where EventName == "MessageSent" and customDimensions.ExperimentID == {experiment_id}
| project UUID, TimeGenerated, EventName;
let MessageReceived = AppInsights
| where EventName == "MessageReceived" and customDimensions.ExperimentID == {experiment_id}
| project UUID, TimeGenerated, EventName;
MessageSent
| join kind=inner MessageReceived on UUID
| project SentTime = MessageSent_TimeGenerated, ReceivedTime = MessageReceived_TimeGenerated
| extend DelayInSeconds = todouble(ReceivedTime - SentTime) / 10000000
'''

headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}

url = f'https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.OperationalInsights/workspaces/{workspace_id}/query?api-version=2021-06-01'
data = {
    'query': query
}
response = requests.post(url, headers=headers, json=data)
rows = response.json()['tables'][0]['rows']

# Calculate and print min, max, and average delay
delays = [row[-1] for row in rows]
min_delay = min(delays)
max_delay = max(delays)
avg_delay = statistics.mean(delays)

print(f'Min delay: {min_delay:.2f} seconds')
print(f'Max delay: {max_delay:.2f} seconds')
print(f'Average delay: {avg_delay:.2f} seconds')
