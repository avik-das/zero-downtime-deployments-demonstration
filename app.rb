#!/usr/bin/env ruby

require 'sinatra'

get '/wait-and-echo' do
  content = params['content']
  sleep(2)

  status(200)
  "ECHO: #{content}"
end
