# digital_ssl_status
used to push expireDays metric to datadog with ssl cert status for endpoints with no agent

This utility will gather the expire date from endpoints listed in the ssl-endpoint.yml located -
(/digital_ssl_status/ci/tasks/get_ssl_info/ssl_endpoints.yml)
It will also extract the expire date from p12 files that are stored in the S3 bucket 
csaa-non-endpoint-certs. The p12 file and password must be added to the params file in pairs, 
non_site_cert is the file name and non_site_cert_pass is the password.
