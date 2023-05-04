import os
import logging
import azure.functions as func
import json
from applicationinsights import TelemetryClient
import time

def main(msg: func.QueueMessage) -> None:
    logging.info('Python Queue trigger function processed a message.')

    # Set up Application Insights
    instrumentation_key = os.environ['APPINSIGHTS_INSTRUMENTATIONKEY']
    tc = TelemetryClient(instrumentation_key)

    # Get message content
    data = json.loads(msg.get_body().decode('utf-8'))
    message_id = data['UUID']
    experiment_id = data['ExperimentID']

    # Log the time received with the UUID from the message
    tc.track_event('MessageReceived', {'UUID': message_id, 'Timestamp': time.time(), 'ExperimentID': experiment_id})
    tc.flush()

