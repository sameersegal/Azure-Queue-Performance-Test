from dotenv import load_dotenv
load_dotenv()
import os
import uuid
import time
import random
import sys
from azure.storage.queue import QueueClient
from applicationinsights import TelemetryClient
import json
from base64 import b64encode

experiment_id = int(sys.argv[1])

# Set up Azure Storage Queue
connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
queue_name = "myqueue"
queue_client = QueueClient.from_connection_string(connection_string, queue_name)
# if not queue_client.exists():
#     queue_client.create_queue()

# Set up Application Insights
instrumentation_key = os.environ['APPINSIGHTS_INSTRUMENTATIONKEY']
tc = TelemetryClient(instrumentation_key)

# Send messages with UUIDs and log the timestamp using Application Insights
for i in range(10):
    message_id = str(uuid.uuid4())
    message = json.dumps({'UUID': message_id, 'ExperimentID': experiment_id})
    message = b64encode(message.encode('utf-8')).decode()
    queue_client.send_message(message)
    tc.track_event('MessageSent', {'UUID': message_id, 'Timestamp': time.time(), 'ExperimentID': experiment_id})
    tc.flush()
    
    # Add variable delay between messages ranging from 1 to 120 seconds
    delay = random.randint(1, 20)
    time.sleep(delay)
print(f"Sent 10 messages to queue for experiment {experiment_id}")
