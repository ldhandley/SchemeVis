require 'aws-sdk'
require "./levels.rb"

aws_access_key_id = 'AKIAIDGOVOANSDVRRO7Q'
aws_secret_access_key = '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'
endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'
region = 'us-east-1'

# Uncomment this line to use in production
# endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'

credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
@mturk = Aws::MTurk::Client.new(endpoint: endpoint, credentials: credentials, region: region)

# This will return $10,000.00 in the MTurk Developer Sandbox
puts @mturk.get_account_balance[:available_balance]


## Grading an assignment
##  Check answers against answer key for that hit type
##  If correctness >80%, approve hit and give qualification for that hit type
##  If correctness >50%, approve hit (Change this??)
##  Else, reject hit

def grade(hit)
   resp = @mturk.list_assignments_for_hit({
      hit_id: hit.hit_id, 
      max_results: 20,
      assignment_statuses: ["Submitted"], # accepts Submitted, Approved, Rejected
    })     

   hit_level = hit.title.split(":")[0]

   puts hit_level

   return if !hit_level.match("Level-")

   answer_key = @levels[hit_level][:answers]

   resp.assignments.each do |assignment| 
     score = grade_assignment(assignment, answer_key)
     worker_id = assignment.worker_id

     puts score.to_s + " " + worker_id

     

     if( score >= 0.8)
        resp = @mturk.associate_qualification_with_worker({
          qualification_type_id: @levels[hit_level][:qualification_id_to_award], # required
          worker_id: worker_id, # required
          integer_value: score*100,
          send_notification: true,
        })

#Maybe message about nex one
#        @mturk.notify_workers({
#          subject: "", # required
#          message_text: "", # required
#          worker_ids: worker_id, # required
#        })
        puts "Awarded qualification: " + hit_level

        resp = @mturk.approve_assignment({
          assignment_id: assignment.assignment_id, # required
          override_rejection: true,
        })
        puts "Assignment approved"

     elsif(score >= 0.5)
        resp = @mturk.approve_assignment({
          assignment_id: assignment.assignment_id, # required
          override_rejection: true,
        })
        puts "Assignment approved"
     else
        resp = @mturk.reject_assignment({
          assignment_id: assignment.assignment_id, # required
          requester_feedback: "Sorry, you didn't get a score of at least 50%. You might need to spend a little more time answering these puzzles next time.", # required
        })
        puts "REJECTED"
     end
   end
end

def grade_assignment(assignment, answer_key)
  worker_answers = assignment.answer.scan(/<QuestionIdentifier>q(\d+)<\/QuestionIdentifier>\n*<FreeText>(.+?)<\/FreeText>/).sort{|a,b| a[0].to_i - b[0].to_i}.map{|a| a[1]}
 
  return 1.0 * worker_answers.zip(answer_key)
                             .map{|f,s| f == s}
                             .count(true) / answer_key.size 

  #score = 0
  #worker_answers.each_with_index do |answer,i|
  #  if(answer == answer_key[i])
  #    score += 0.1
  #  end
  #end
  #return score
end

## Fetch hits
## For each hit, grade submitted assignments...

resp = @mturk.list_hits({
  max_results: 100,
})

resp.hits.each do |hit|
  grade(hit)
end









