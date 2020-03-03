require 'cgi'
require 'digest'
require 'net/http'
require 'json'

class UnitPay
	def initialize(domain, secretKey)
		@formUrl = 'https://' + domain + '/pay/'
		@secretKey = secretKey

		@supportedUnitpayMethods = ['initPayment', 'getPayment']
		@requiredUnitpayMethodsParams = {
			'initPayment'	=>	['desc', 'account', 'sum', 'paymentType', 'projectId'],
			'getPayment'	=>	['paymentId']
		}
		@supportedPartnerMethods = ['check', 'pay', 'error']
		@supportedUnitpayIp = [
			'31.186.100.49',
        	'178.132.203.105',
        	'52.29.152.23',
        	'52.19.56.234',
        	'127.0.0.1' # for debug
		]
		@apiUrl = 'https://' + domain + '/api'
	end
	def form(publicKey, sum, account, desc, currency = 'RUB', locale = 'ru')

		params = {
            'account' => account,
            'currency' => currency,
            'desc' => desc,
            'sum' => sum,
        }
        if  (defined? @secretKey)
        	params['signature'] = getSignature(params, "check")
        end
        params['locale'] = locale

        querystring = params.map{|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
        return @formUrl + publicKey + '?' + querystring
	end
	def getSignature( params, method = nil )
		params.delete('sign')
		params.delete('signature')
		mas = params.sort
		mas.push(["1", @secretKey])
		if (!method.nil?)
			mas.unshift(["method",method])
		end
		params = Hash[mas]
		str = params.map{|k,v| "#{v}"}.join('{up}')
		h = Digest::SHA256.hexdigest str
		return h
	end
	def api( method, params = {} )

		if !@supportedUnitpayMethods.include?(method)
			raise 'Method is not supported'
		end

		if !@requiredUnitpayMethodsParams[method].nil?
			@requiredUnitpayMethodsParams[method].each do |item|
				if params[item].nil?
					raise "param " + item + " is null"
				end
			end
		end

		params['secretKey'] = @secretKey

		querystring = params.map{|k,v| "params[#{CGI.escape(k)}]=#{CGI.escape(v)}"}.join("&")
		requestUrl = @apiUrl + '?method=' + method + '&' + querystring

		puts(requestUrl)
		data = Net::HTTP.get_response(URI.parse(requestUrl)).body
		json = JSON.parse(data)

		return json

	end

	def checkHandlerRequest(method, params, ip)
		if !@supportedPartnerMethods.include?(method)
			raise 'method is not supported'
		end
		signature = getSignature(params, method)
		if params['signature'] != signature
			raise 'wrong signature'
		end
		if !@supportedUnitpayIp.include?(ip)
			raise 'IP address error'
		end
		return true
	end

	def getSuccessHandlerResponse( message )
		return JSON.generate({'result'=>{'message'=>message}})
	end
	def getErrorHandlerResponse( message )
		return JSON.generate({'error'=>{'message'=>message}})
	end

end