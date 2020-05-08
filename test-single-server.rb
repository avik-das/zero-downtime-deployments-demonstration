#!/usr/bin/env ruby

require 'curses'
require 'net/http'

include Curses

## DATA + BEHAVIOR ############################################################

class Request
  STATE_WAITING = 1
  STATE_SUCCESS = 2
  STATE_ERROR   = 3

  def initialize(num)
    @num = num
    @state = STATE_WAITING

    start = Time.now
    Thread.new {
      uri = URI('http://localhost:4567/wait-and-echo')
      uri.query = URI.encode_www_form({ content: "Request #{@num}" })

      begin
        # If the request succeeds without an exception, assume the server
        # returned a successful response. The only mode of failure is an
        # inability to connect.
        @response = Net::HTTP.get_response(uri).body
        @state = STATE_SUCCESS
      rescue Errno::ECONNREFUSED
        @state = STATE_ERROR
      end

      @duration_ms = Time.now - start
    }
  end

  def duration_seconds; (@duration_ms * 1000).floor; end

  attr_reader \
    :num, \
    :state, \
    :response, \
    :duration_ms
end

REQUEST_INTERVAL_MS = 200
NUM_REQUESTS_BEFORE_SHUTDOWN = 20
TOTAL_REQUESTS = 40

REQUESTS = []
SERVER_PID = spawn(RbConfig.ruby, 'app.rb', [:out, :err] => 'out.log')
sleep(1)

def run_requests
  begin
    TOTAL_REQUESTS.times do |i|
      sleep(REQUEST_INTERVAL_MS / 1000.0)
      REQUESTS << Request.new(i)

      Process.kill('TERM', SERVER_PID) \
        if i == (NUM_REQUESTS_BEFORE_SHUTDOWN - 1)
    end
  end
end

## UI CONSTANTS + HELPERS #####################################################

COLOR_DEFAULT = 1
COLOR_WAITING = 2
COLOR_SUCCESS = 3
COLOR_ERROR   = 4

WIDTH_COL_0 = 3
WIDTH_COL_1 = 32
WIDTH_COL_2 = 'Duration (ms)'.length
COL_PADDING = ' '
COL_SEPARATOR = '│'

def resize_to(str, width)
  case str.size
  when width then str
  when 0...width then str.ljust(width)
  else "#{str[0...(width - 3)]}..."
  end
end

def table_row(col0, col1, col2)
  COL_PADDING +
    resize_to(col0, WIDTH_COL_0) +
    COL_PADDING +
    COL_SEPARATOR +
    COL_PADDING +
    resize_to(col1, WIDTH_COL_1) +
    COL_PADDING +
    COL_SEPARATOR +
    COL_PADDING +
    resize_to(col2, WIDTH_COL_2)
end

HEADER =
  COL_PADDING +
    resize_to('#', WIDTH_COL_0) +
    COL_PADDING +
    COL_SEPARATOR +
    COL_PADDING +
    resize_to('Response', WIDTH_COL_1) +
    COL_PADDING +
    COL_SEPARATOR +
    COL_PADDING +
    resize_to('Duration (ms)', WIDTH_COL_2)

HEADER_ROW_SEPARATOR =
  '━' * (COL_PADDING.size + WIDTH_COL_0 + COL_PADDING.size) +
  '┿' +
  '━' * (COL_PADDING.size + WIDTH_COL_1 + COL_PADDING.size) +
  '┿' +
  '━' * (COL_PADDING.size + WIDTH_COL_2 + COL_PADDING.size)

## UI INITIALIZATION ##########################################################

init_screen
start_color
curs_set(0) # hide cursor
noecho      # disable showing typed characters

# All on black
init_pair(COLOR_DEFAULT, COLOR_WHITE , COLOR_BLACK)
init_pair(COLOR_WAITING, COLOR_YELLOW, COLOR_BLACK)
init_pair(COLOR_SUCCESS, COLOR_GREEN , COLOR_BLACK)
init_pair(COLOR_ERROR  , COLOR_RED   , COLOR_BLACK)

## MAIN LOOP ##################################################################

begin
  win = Curses::Window.new(0, 0, 1, 2)
  win.timeout = 100

  Thread.new { run_requests }

  loop do
    win.setpos(0,0)

    win.attron(color_pair(COLOR_DEFAULT) | A_BOLD) { win << HEADER }
    clrtoeol
    win << "\n"

    win.attron(color_pair(COLOR_DEFAULT)) { win << HEADER_ROW_SEPARATOR }
    clrtoeol
    win << "\n"

    REQUESTS.each do |req|
      win.attron(color_pair(COLOR_DEFAULT)) {
        win << COL_PADDING
        win << resize_to(req.num.to_s, WIDTH_COL_0)
        win << COL_PADDING
        win << COL_SEPARATOR
        win << COL_PADDING
      }

      color, response, duration =
        case req.state
        when Request::STATE_WAITING
          [
            color_pair(COLOR_WAITING),
            'Waiting...',
            ''
          ]
        when Request::STATE_SUCCESS
          [
            color_pair(COLOR_SUCCESS) | A_BOLD,
            req.response,
            req.duration_seconds.to_s
          ]
        when Request::STATE_ERROR
          [
            color_pair(COLOR_ERROR) | A_BOLD,
            'Error',
            req.duration_seconds.to_s
          ]
        end
      win.attron(color) { win << resize_to(response, WIDTH_COL_1) }

      win.attron(color_pair(COLOR_DEFAULT)) {
        win << COL_PADDING
        win << COL_SEPARATOR
        win << COL_PADDING
        win << resize_to(duration, WIDTH_COL_2)
      }

      clrtoeol
      win << "\n"
    end

    (win.maxy - win.cury).times { win.deleteln }
    win.refresh

    exit 0 if win.get_char == 'q'
  end
ensure
  close_screen
  Process.kill('TERM', SERVER_PID)
end
