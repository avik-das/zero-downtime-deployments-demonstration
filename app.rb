#!/usr/bin/env ruby

require 'sinatra'

ECHO_PREFIX =
  if ENV['UPDATED'] == 'Y' then 'ECHO (updated)'
  else 'ECHO'
  end

get '/health' do status(204) end

get '/wait-and-echo' do
  content = params['content']
  sleep(2)

  status(200)
  "#{ECHO_PREFIX} from #{settings.port}: #{content}"
end
