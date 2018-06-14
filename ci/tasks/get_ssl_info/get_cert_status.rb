#!/usr/bin/env ruby
require 'date'
require 'time'
require 'yaml'
require 'timeout'
require 'aws-sdk-s3'
wrkdir = Dir.pwd

#file with SSL endpoints to be monitored
endpoints = YAML.load(File.open("digital-ssl-status-repo/ci/tasks/get_ssl_info/ssl_endpoints.yml"))

endpoints.each_key do |key|
  endpoint = endpoints[key]['endpoint']
  port = endpoints[key]['port']

  #check if url is active if not exit at rescue
  begin
    Timeout::timeout(5){check_url = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`}
    #query endpoint for SSL information
    get_dates = `echo | openssl s_client -servername #{endpoints[key]['endpoint']} -connect #{endpoints[key]['endpoint']}:#{endpoints[key]['port']} 2>/dev/null | openssl x509 -noout -dates`
    expire = Time.parse(get_dates.split("notAfter=")[1].to_s).utc
    expireDays = ((expire - Time.now).to_i / 86400)
    puts "Pushing Metrics to Datadog for #{endpoints[key]['endpoint']} "
    currenttime = Time.now.to_i
    #push data to Datadog
    datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
          '{"series":\
              [{"metric":"digital.cert.days_to_expiration}",
                "points":[[#{currenttime}, #{expireDays}]],
                "type":"gauge",
                "host":"#{endpoints[key]['endpoint']}",
                "tags":["name:#{endpoints[key]['endpoint']}"]}]}' \
                https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`

    rescue Timeout::Error
      #display information for bad endpoint
      puts "#{endpoints[key]['endpoint']} timed out! -- Check endpoint for validity"
    end
end

#create String from enviornment varable string
file_name_str = "#{ENV['NON_SITE_CERTS']}"
secret_str = "#{ENV['NON_SITE_CERTS_PASS']}"
#Create Array from string
file_name_arr = file_name_str.split(", ")
secret_arr = secret_str.split(", ")
#Create hash by combining arrays (file_name_arr and secret_arr)
cert_values = Hash[file_name_arr.zip secret_arr]
#loop though gathering data and posting to Datadog
cert_values.each do |file_name, secret|
  #Connect to s3
  s3 = Aws::S3::Resource.new(
    access_key_id: "#{ENV['AWS_ACCESS_KEY']}",
    secret_access_key: "#{ENV['AWS_SECRET_KEY']}",
    region: "us-east-1"
  )
  #Get File from s3 Bucket
  s3.bucket('csaa-non-endpoint-certs').object("#{file_name}").get(response_target: "#{file_name}")
  #extract p12 file to cer and get the days to expire
  extract_cer = `openssl pkcs12 -in #{file_name} -out certcheck.cer -nodes -password pass:#{secret}`
  get_expire = `cat certcheck.cer | openssl x509 -noout -enddate`
  expire = Time.parse(get_expire.split("notAfter=")[1].to_s).utc
  expireDays = ((expire - Time.now).to_i / 86400)
  puts "Pushing Metrics to Datadog for #{file_name} "
  currenttime = Time.now.to_i
  #pushing data to Datadog
  datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
        '{"series":\
            [{"metric":"digital.cert.days_to_expiration}",
              "points":[[#{currenttime}, #{expireDays}]],
              "type":"gauge",
              "host":"#{file_name}",
              "tags":["name:#{file_name}"]}]}' \
              https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`
  #clean up file from Instance
  File.delete("certcheck.cer") if File.exist?("certcheck.cer")
  File.delete("#{file_name}") if File.exist?("#{file_name}")

end
