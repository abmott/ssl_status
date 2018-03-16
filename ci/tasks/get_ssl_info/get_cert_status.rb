#!/usr/bin/env ruby
require 'date'
require 'time'
require 'yaml'
puts "hello"
#datadogprogress = "Pushing Metrics to Datadog"
#
#endpoints = YAML.load(File.open("ci/tasks/get_ssl_info/ssl_endpoints.yml"))
#
#endpoints.each_key do |key|
#endpoint = endpoints[key]['endpoint']
#port = endpoints[key]['port']
##puts "#{endpoint}"
#get_dates = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`
#expire = Time.parse(get_dates.split("notAfter=")[1].to_s).utc
##puts expire
#expireDays = ((expire - Time.now).to_i / 86400)
##puts expireDays
##
#    #curl Metric to DataDog
#    printf("\r#{datadogprogress}")
#    datadogprogress = datadogprogress.concat(".")
#    currenttime = Time.now.to_i
#    datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
#          '{"series":\
#              [{"metric":"digital.cert.days_to_expiration}",
#               "points":[[#{currenttime}, #{expireDays}]],
#               "type":"gauge",
#               "host":"#{endpoints[key]['endpoint']}",
#               "tags":["name:#{endpoints[key]['endpoint']}"]}]}' \
#               https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`
#  #puts datadogoutput
#end
