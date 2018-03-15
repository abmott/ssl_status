#!/usr/bin/env ruby
require 'json'
require 'aws-sdk-s3'
require 'date'
require 'time'
require 'yaml'

wrkdir = Dir.pwd
datadogprogress = "Pushing Metrics to Datadog"

endpoints = begin YAML.load(File.open("ssl_endpoints.yml"))
#  rescue ArgumentError => e
#  puts "Could not parse Endpoints YAML: #{e.message}"
#end

endpoints.each_key { |key|
endpoint = endpoints[key]['endpoint']
port = endpoints[key]['port']
puts "#{endpoint} => #{port}"
get_dates = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`
expire = Time.parse(get_dates.split("notAfter=")[1].to_s).utc
puts expire
expireDays = ((expire - Time.now).to_i / 86400)
puts expireDays
#
    #curl Metric to DataDog
    printf("\r#{datadogprogress}")
    datadogprogress = datadogprogress.concat(".")
    currenttime = Time.now.to_i
    datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
          '{"series":\
              [{"metric":"digital.cert.days_to_expiration}",
               "points":[[#{currenttime}, #{expireDays}]],
               "type":"gauge",
               "host":"#{endpoints[key]['endpoint']}",
               "tags":["name:#{endpoints[key]['endpoint']}"]}]}' \
               https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`
  #puts datadogoutput
}
#products_list.puts ".................."
#products_list.close
#
#puts ""
#File.open("#{wrkdir}/#{ENV['PCF_ENVIRONMENT']}-current_certs.yml").each do |line|
#  puts line
#end
#
#s3 = Aws::S3::Resource.new(
#  :access_key_id => "#{ENV['AWS_ACCESS_KEY']}",
#  :secret_access_key => "#{ENV['AWS_SECRET_KEY']}",
#  :region => 'us-east-1'
#)
#
#file = "#{ENV['PCF_ENVIRONMENT']}-current_certs.yml"
#bucket = 'csaa-pcf-info'
#
#name = File.basename(file)
#
#obj = s3.bucket(bucket).object(name)
#
#obj.upload_file(file)
#
#File.delete("#{wrkdir}/#{ENV['PCF_ENVIRONMENT']}-current_certs.yml") if File.exist?("#{wrkdir}/#{ENV['PCF_ENVIRONMENT']}-current_certs.yml")
