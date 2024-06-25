#!/usr/bin/env ruby

require 'websocket-client-simple'
require 'json'

WEBSOCKET_URL = 'ws://localhost:5000/cable'

ws = WebSocket::Client::Simple.connect WEBSOCKET_URL

subscription_confirmed = false

ws.on :open do
  # puts "Connected to #{WEBSOCKET_URL}"

  # Subscribe to the channel
  ws.send({
    command: 'subscribe',
    identifier: { channel: 'CLIChannel' }.to_json
  }.to_json)
end

ws.on :message do |msg|
  data = JSON.parse(msg.data)
  # puts "Received message: #{data}" # Debug output

  if data['type'] == 'ping'
    ws.send({ type: 'pong' }.to_json)
  elsif data['type'] == 'confirm_subscription'
    # puts "Subscription confirmed"
    subscription_confirmed = true

    # Send the command after subscription is confirmed
    ws.send({
      command: 'message',
      identifier: { channel: 'CLIChannel' }.to_json,
      data: { command: ARGV[0], args: ARGV[1..-1] }.to_json
    }.to_json)
  elsif data['message'] && data['message']['output']
    puts data['message']['output']
    exit
  end
end

ws.on :error do |e|
  puts "Error: #{e.message}"
  puts "Error type: #{e.class}"
  puts e.backtrace.join("\n")
end

ws.on :close do |e|
  puts "Connection closed (#{e.code})"
  exit
end

loop do
  sleep 1
end