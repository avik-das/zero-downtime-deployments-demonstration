#!/usr/bin/env ruby

require 'sinatra'

get '/health' do status(204) end

get '/wait-and-echo' do
  content = params['content']
  sleep(2)

  status(200)
  "ECHO: #{content}"
end
