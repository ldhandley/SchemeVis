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

@level   = ARGV[0]
@version = ARGV[1]

def grade(hit)
   resp = @mturk.list_assignments_for_hit({
      hit_id: hit.hit_id, 
      max_results: 20,
      assignment_statuses: ["Approved"], # accepts Submitted, Approved, Rejected
    })     

   hit_level = hit.title.split(":")[0]

   return if !hit_level.match(@level)

   version = hit.question.match(/s3.amazonaws.com\/thoughtstem.cms.dev\/SchemeVis\/#{hit_level}\/(v\d+)/)[1] rescue return

   return if !version.match(@version)

   answer_key = @levels[hit_level][version][:answers]

   resp.assignments.each do |assignment| 
     score = grade_assignment(assignment, answer_key)
     worker_id = assignment.worker_id

     resp = @mturk.associate_qualification_with_worker({
        qualification_type_id: @levels[hit_level][version][:qualification_id_to_award], # required
        worker_id: worker_id, # required
        integer_value: score*100,
        send_notification: true,
     })

     puts "Awarded qualification: " + hit_level
   end
end

def grade_assignment(assignment, answer_key)
  worker_answers = assignment.answer.scan(/<QuestionIdentifier>q(\d+)<\/QuestionIdentifier>\n*<FreeText>(.+?)<\/FreeText>/).sort{|a,b| a[0].to_i - b[0].to_i}.map{|a| a[1]}
 
  return 1.0 * worker_answers.zip(answer_key)
                             .map{|f,s| f == s}
                             .count(true) / answer_key.size 
end

## Fetch hits
## For each hit, grade submitted assignments...

resp = @mturk.list_hits({
  max_results: 100,
})

resp.hits.each do |hit|
  grade(hit)
end









