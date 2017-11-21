require 'aws-sdk'
require "./levels.rb"
require "../aws_creds.rb"

aws_access_key_id = @aws_access_key_id
aws_secret_access_key = @aws_secret_access_key
endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'
region = 'us-east-1'

# Uncomment this line to use in production
# endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'

credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
@mturk = Aws::MTurk::Client.new(endpoint: endpoint, credentials: credentials, region: region)

# This will return $10,000.00 in the MTurk Developer Sandbox
puts @mturk.get_account_balance[:available_balance]

@assignment_id = ARGV[0]

resp = @mturk.approve_assignment({
  assignment_id: @assignment_id, # required
  requester_feedback: "Reversing our previously mistaken rejection!",
  override_rejection: true,
})


