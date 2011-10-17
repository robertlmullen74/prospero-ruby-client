#This is the main driver file for the application, it's sort of RESTful and uses sinatra
#	1. Provides a listener endpoint that will return the form post variables.
#	2. Easy way to subscribe and unsubscribe to messages.
#	3. Eventually tie into a UI client so we can easily 'tap' into messages coming from prospero, allowing us to easily test.
require 'rubygems'
require 'sinatra'
require 'net/http'
require 'uri'
require 'json/pure'
require 'date'
require 'time'
require 'cmac/cmac'

#$callBackUrl = 'http://localhost:4567/listen'
$KCODE = "U"

get '/subscriptions/whittaker-dupe-result' do
	headers \
      "content-type"   => "application/json"
	#JSON.pretty_generate($results)
	document = JSON 'test'  => 23 # => "{\"test\":23}"
	subscribe_message('Whittaker.Institution.Created', $callBackUrl)

end

post '/listen' do
  puts params.inspect
  #status 416
  params.inspect

  'I am posted to'
end

#Attempts subscribe
def subscribe_message(messageType, callBackUrl)

	results = Hash.new
	prosperoMessage = Hash.new
	http = Net::HTTP.new('prosperoUrl')
	path = '/v1/subscription'
	
	headers = {
		'Host' => 'prosperoUrl'
	}

	#Build the prospero message
	prosperoMessage['timeStamp'] = Time.now.utc.iso8601
    prosperoMessage['callBackUrl'] = callBackUrl
	prosperoMessage['messageType'] = messageType
	prosperoMessage['path'] = path 

	digest = get_auth_digest prosperoMessage
	authorization = 'ONE' + "|" + prosperoMessage['timeStamp']  + "|" + digest;
	prosperoMessage['postData']  = 'MESSAGE-TYPE=' + messageType + '&CALLBACK-URL=' + callBackUrl + '&AUTHORIZATION=' + authorization

	# Perform the post to subscribe
	resp, data = http.post(path, prosperoMessage['postData'], headers)

	# Output on the screen 
	results['responseCode'] = resp.code
	results['message'] = resp.message
	resp.each {|key, val| results[key] = val}
	results['responseData'] = data
	h = results.merge(prosperoMessage)
	# Format JSON
	JSON.pretty_generate(h)

end

# generates the authToken for authorization
def get_auth_digest (prosperoMessage)
	#TODO: this comes from config
	concat = concat_string prosperoMessage	
	sharedkey = '1234567890123456'
		cmac = Digest::CMAC.new(OpenSSL::Cipher::Cipher.new('aes-128-cbc'), "1234567890123456")
	cmac.update(concat)	
	cmac.digest.unpack('H*')[0]
	
end


def concat_string prosperoMessage
	concat = prosperoMessage['timeStamp']
	concat += prosperoMessage['callBackUrl']
	#utfMessageType = prosperoMessage['messageType'].unpack("U*")
	#puts 'utfMessageType' + utfMessageType
	concat += prosperoMessage['messageType']
	concat
end 

