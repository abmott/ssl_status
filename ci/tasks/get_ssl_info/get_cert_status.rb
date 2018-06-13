#!/usr/bin/env ruby
require 'date'
require 'time'
require 'yaml'
require 'timeout'
wrkdir = Dir.pwd

datadogprogress = "Pushing Metrics to Datadog"

endpoints = YAML.load(File.open("digital-ssl-status-repo/ci/tasks/get_ssl_info/ssl_endpoints.yml"))

endpoints.each_key do |key|
endpoint = endpoints[key]['endpoint']
port = endpoints[key]['port']
#puts "#{endpoint}"
#check if url is active
begin
  Timeout::timeout(5){check_url = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`}

  get_dates = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`
  expire = Time.parse(get_dates.split("notAfter=")[1].to_s).utc
  #puts expire
  expireDays = ((expire - Time.now).to_i / 86400)
  #puts expireDays
  #
      #curl Metric to DataDog
      #printf("\r#{datadogprogress}")
      #datadogprogress = datadogprogress.concat(".")
      puts "Pushing Metrics to Datadog for #{endpoints[key]['endpoint']} "
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
rescue Timeout::Error
  puts "URL timed out!"
end
end

secret = "#{ENV['NON_SITE_CERTS1_PASS']}"
file = "#{ENV['NON_SITE_CERTS1']}"
extract_cer = `openssl pkcs12 -in ./digital-ssl-status-repo/ci/tasks/get_ssl_info/non_site_certs/#{file} -out ./digital-ssl-status-repo/ci/tasks/get_ssl_info/non_site_certs/certcheck.cer -nodes -password pass:#{secret}`
get_expire = `cat certcheck.cer | openssl x509 -noout -enddate`
#puts get_expire
expire = Time.parse(get_expire.split("notAfter=")[1].to_s).utc
#puts expire
expireDays = ((expire - Time.now).to_i / 86400)
#puts expireDays
#curl Metric to DataDog
#printf("\r#{datadogprogress}")
#datadogprogress = datadogprogress.concat(".")
puts "Pushing Metrics to Datadog for #{ENV['NON_SITE_CERTS1']} "
currenttime = Time.now.to_i
datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
      '{"series":\
          [{"metric":"digital.cert.days_to_expiration}",
           "points":[[#{currenttime}, #{expireDays}]],
           "type":"gauge",
           "host":"#{ENV['NON_SITE_CERTS1']}",
           "tags":["name:#{ENV['NON_SITE_CERTS1']}"]}]}' \
           https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`

File.delete("./digital-ssl-status-repo/ci/tasks/get_ssl_info/non_site_certs/certcheck.cer") if File.exist?("./digital-ssl-status-repo/ci/tasks/get_ssl_info/non_site_certs/certcheck.cer")
#puts datadogoutput
