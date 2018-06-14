#!/usr/bin/env ruby
require 'date'
require 'time'
require 'yaml'
require 'timeout'
require 'aws-sdk-s3'
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
  puts "#{endpoints[key]['endpoint']} timed out!"
end
end


file_name_str = "#{ENV['NON_SITE_CERTS']}"
secret_str = "#{ENV['NON_SITE_CERTS_PASS']}"
file_name_arr = file_name_str.split(", ")
secret_arr = secret_str.split(", ")
cert_values = Hash[file_name_arr.zip secret_arr]

cert_values.each do |file_name, secret|

  s3 = Aws::S3::Resource.new(
    access_key_id: "#{ENV['AWS_ACCESS_KEY']}",
    secret_access_key: "#{ENV['AWS_SECRET_KEY']}",
    region: "us-east-1"
  )
  puts file_name
  s3.bucket('csaa-non-endpoint-certs').object("#{file_name}").get(response_target: "#{file_name}")



  extract_cer = `openssl pkcs12 -in #{file_name} -out certcheck.cer -nodes -password pass:#{secret}`
  get_expire = `cat certcheck.cer | openssl x509 -noout -enddate`
  #puts get_expire
  expire = Time.parse(get_expire.split("notAfter=")[1].to_s).utc
  #puts expire
  expireDays = ((expire - Time.now).to_i / 86400)
  puts expireDays
  #puts expireDays
  #curl Metric to DataDog
  #printf("\r#{datadogprogress}")
  #datadogprogress = datadogprogress.concat(".")
  puts "Pushing Metrics to Datadog for #{file_name} "
  currenttime = Time.now.to_i
  datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
        '{"series":\
            [{"metric":"digital.cert.days_to_expiration}",
              "points":[[#{currenttime}, #{expireDays}]],
              "type":"gauge",
              "host":"#{file_name}",
              "tags":["name:#{file_name}"]}]}' \
              https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`

  File.delete("certcheck.cer") if File.exist?("certcheck.cer")
  File.delete("#{file_name}") if File.exist?("#{file_name}")

end
#puts datadogoutput
cert_file_strg = "#{ENV['ARRAY_TEST']}"
cert_pass_strg = "#{ENV['ARRAY_TEST2']}"
cert_file = cert_file_strg.split(", ")
cert_pass = cert_pass_strg.split(", ")

cert_values = Hash[cert_file.zip cert_pass]
cert_values.each do |cert, pass|
  puts "#{cert}"
  puts "#{pass}"
end
