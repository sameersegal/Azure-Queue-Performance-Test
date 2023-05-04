#!/bin/bash

experiment_id=1

code=$(
  openssl rand -hex 2 | tr -d '\n'
  echo
)
echo "Run Code: $code"

# Set your function app name
function_app_name="azure-qtest-func"

# Set your function app resource group
resource_group="azure-qtest"

# Path to send_messages.py
send_messages_script="send_messages.py"

# Path to analyze_results.py
analyze_results_script="analyze.py"

# Path to host.json
host_json_file="func/host.json"

# Log file for the experiment results
log_file="experiment_results-$code.log"

# Parameter ranges and steps
visibility_timeouts=(1000 5000)
batch_sizes=(1 16)
new_batch_thresholds=(1 8)
max_polling_intervals=(100 500 1000 2000)

# Iterate through the parameters
for visibility_timeout in "${visibility_timeouts[@]}"; do
  for batch_size in "${batch_sizes[@]}"; do
    for new_batch_threshold in "${new_batch_thresholds[@]}"; do
      for max_polling_interval in "${max_polling_intervals[@]}"; do
        # Update host.json with new values
        jq ".extensions.queues |= . + {maxPollingInterval: $max_polling_interval, batchSize: $batch_size, newBatchThreshold: $new_batch_threshold, visibilityTimeout: $visibility_timeout}" "$host_json_file" >"$host_json_file.tmp"
        mv "$host_json_file.tmp" "$host_json_file"

        cd func

        # Deploy the function to Azure
        func azure functionapp fetch-app-settings azure-qtest-func
        func azure functionapp publish azure-qtest-func
        
        cd -

        sleep 120

        # Run send_messages.py
        echo "Starting script to send messages"
        poetry run python3 "$send_messages_script" "$code-$experiment_id"

        # Wait for a while to ensure all messages are processed
        sleep 180

        # Run analyze_results.py and save results
        result=$(poetry run python3 "$analyze_results_script" "$code-$experiment_id")
        echo "MaxPollingInterval: $max_polling_interval, BatchSize: $batch_size, NewBatchThreshold: $new_batch_threshold, VisibilityTimeout: $visibility_timeout, $result"
        echo "MaxPollingInterval: $max_polling_interval, BatchSize: $batch_size, NewBatchThreshold: $new_batch_threshold, VisibilityTimeout: $visibility_timeout, $result" >>"$log_file"

        experiment_id=$((experiment_id + 1))
      done
    done
  done
done
