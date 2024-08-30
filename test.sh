#!/bin/bash
#
# This script tests the load balancing, high availability, and failover capabilities of the HAProxy setup.
#
# Load Balancing Test: Sends multiple requests to the virtual IP to verify that responses are being served by different backend servers.
# High Availability Test: Simulates a failure of LB1 by stopping its Keepalived container, checks if LB2 takes over, and then restores LB1 to check if it reclaims the virtual IP.
# Backend Server Failure Test: Stops one of the backend servers to see if HAProxy continues to serve requests using the remaining server, then restarts the stopped server.
#

# Function to test load balancing
test_load_balancing() {
  echo "Testing Load Balancing..."
  for i in {1..10}; do
    response=$(curl -s http://172.18.0.100)
    echo "Response $i: $response"
    sleep 1
  done
}

# Function to test high availability
test_high_availability() {
  echo "Testing High Availability..."

  # Stop Keepalived on LB1 to simulate failure
  echo "Stopping Keepalived on LB1..."
  docker stop keepalived1
  sleep 5

  # Test if LB2 has taken over
  echo "Checking if LB2 has taken over..."
  for i in {1..5}; do
    response=$(curl -s http://172.18.0.100)
    echo "Response during failover $i: $response"
    sleep 1
  done

  # Restart Keepalived on LB1
  echo "Restarting Keepalived on LB1..."
  docker start keepalived1
  sleep 5

  # Test if LB1 has reclaimed the virtual IP
  echo "Checking if LB1 has reclaimed the virtual IP..."
  for i in {1..5}; do
    response=$(curl -s http://172.18.0.100)
    echo "Response after failback $i: $response"
    sleep 1
  done
}

# Function to test backend server failure
test_backend_failure() {
  echo "Testing Backend Server Failure..."

  # Stop one backend server
  echo "Stopping Backend Server 1..."
  docker stop server1
  sleep 5

  # Test if HAProxy continues to serve requests
  echo "Checking HAProxy behavior with one backend server down..."
  for i in {1..5}; do
    response=$(curl -s http://172.18.0.100)
    echo "Response with one backend down $i: $response"
    sleep 1
  done

  # Restart the backend server
  echo "Restarting Backend Server 1..."
  docker start server1
  sleep 5
}

# Run tests
test_load_balancing
test_high_availability
test_backend_failure

echo "Testing completed."
