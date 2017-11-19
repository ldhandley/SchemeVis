require 'aws-sdk'
require 'erb'

require "./levels.rb"

aws_access_key_id = 'AKIAIDGOVOANSDVRRO7Q'
aws_secret_access_key = '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'
endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'
region = 'us-east-1'

# Uncomment this line to use in production
# endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'

credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
@mturk = Aws::MTurk::Client.new(endpoint: endpoint, credentials: credentials, region: region)

puts @mturk.get_account_balance[:available_balance]

@level = ARGV[0]
@previous_level = "Level-#{@level.split("-")[1].to_i - 1}"

resp1 = @mturk.list_workers_with_qualification_type({
  qualification_type_id: @levels[@previous_level][:qualification_id_to_award], # required
  status: "Granted", # accepts Granted, Revoked
  max_results: 100,
})

resp2 = @mturk.list_workers_with_qualification_type({
  qualification_type_id: @levels[@level][:qualification_id_to_award], # required
  status: "Granted", # accepts Granted, Revoked
  max_results: 100,
})


these         = resp1.qualifications.map(&:worker_id)
but_not_these = resp2.qualifications.map(&:worker_id)

to_message = these - but_not_these


@mturk.notify_workers({
  subject: "Special HITs available", # required
  message_text: "Since you've successfully completed our #{@previous_level} puzzles, you are qualified to do more advanced #{@level} puzzles.  These are available now!  You can find them by searching Mechanical Turk for \"#{@level}: Solve some puzzles\".", # required
  worker_ids: to_message, # required
})



