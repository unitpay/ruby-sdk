#Unitpay
##Установка
Внесите эту строчку в ваш gem файл
```ruby
gem 'unitpay-api'
```
И затем выполните команду
```ruby
    bundle
```
Или установите вручную с помощью
```ruby
    gem install unitpay_api
```
Теперь включите в проект с помощью
```ruby
    require 'unitpay_api'
```    
##Примеры использования апи для фраймворка Rails
###Пример использования апи для отображения формы:

```ruby
class UnitpayController < ApplicationController
  def payment
  	secretKey = 'asdfsd3243adsfa32fsa2345r3e3w3rf'
  	publicKey = '9978-2bfc2'
  	summ = '10.00'
  	account = 'asdf-1234-fds1'
  	desc = 'Платеж по заказу'
  	
    unitpay = UnitPay.new(secretKey)
    url = unitpay.form(publicKey, summ, account, desc)
    redirect_to url
  end
end
```

###Пример использования апи для написания запросов к сервису unitpay.ru

```ruby
class UnitpayController < ApplicationController
  def payment

    secretKey = 'asdfsd3243adsfa32fsa2345r3e3w3rf'
    publicKey = '9978-2bfc2'
    summ = '10.00'
    account = 'asdf-1234-fds1'
    desc = 'Платеж по заказу'
    currency = 'RUB'
    projectId = '9978'

    unitpay = UnitPay.new(secretKey)
    response = unitpay.api('initPayment', {
        'account' => account,
        'desc' => desc,
        'sum' => summ,
        'paymentType' => 'yandex',
        'currency' => currency,
        'projectId' => projectId,
    });

    #If need user redirect on Payment Gate
    if !!response['result'] && !!response['result']['type'] && response['result']['type'] == 'redirect'
      # Url on PaymentGate
      url = response['result']['redirectUrl']
      # Payment ID in Unitpay (you can save it)
      paymentId = response['result']['paymentId']
      # User redirect
      redirect_to url
    elsif !!response['result'] && !!response['result']['type'] && response['result']['type'] == 'invoice'
      # Url on receipt page in Unitpay
        url = response['result']['receiptUrl']
        # Payment ID in Unitpay (you can save it)
        paymentId = response['result']['paymentId']
        # Invoice Id in Payment Gate (you can save it)
        invoiceId = response['result']['invoiceId']
        # User redirect
        redirect_to url
      elsif !!response['error'] && !!response['error']['message']
        # text error message
        error = response['error']['message']
    end
  end
end
```


###пример callback'а
```ruby
class UnitpayController < ApplicationController
  def callback
    secretKey = 'asdfsd3243adsfa32fsa2345r3e3w3rf'
    summ = '10.00'
    account = 'asdf-1234-fds1'
    currency = 'RUB'
    projectId = '9978'

    begin
        unitpay = UnitPay.new(secretKey)
        method = params[:method]
        if params[:params].nil?
          p = {}
        else
          p = params[:params]
        end
        ip = request.remote_ip

        unitpay.checkHandlerRequest(method, params, ip)
        if p['orderSum'] != summ ||
          p['orderCurrency'] != currency ||
          p['account'] != account ||
          p['projectId'] != projectId

          raise 'Order validation error'
        end

        if ( method == 'check' )
          json = unitpay.getSuccessHandlerResponse('Check Success. Ready to pay.')
        elsif( method == 'pay' )
          json = unitpay.getSuccessHandlerResponse('Pay Success')
        elsif( method == 'error' )
          json = unitpay.getSuccessHandlerResponse('Error logged')
        elsif( method == 'refund' )
          json = unitpay.getSuccessHandlerResponse('Order canceled')
        end

        render :json => json
    rescue Exception => e  
        error = e.message
        render :json => unitpay.getErrorHandlerResponse(error)
    end 
  end
end
```

