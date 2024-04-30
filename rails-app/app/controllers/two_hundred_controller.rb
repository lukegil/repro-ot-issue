require 'faraday'


class TwoHundredController < ActionController::API
  def get
    response = Faraday.get('https://httpstat.us/200')
    puts "Status: #{response.status}"
    puts "Response body: #{response.body}"

    render json: { status: response.status }
  end
end

