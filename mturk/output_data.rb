require 'aws-sdk'
require 'json'
require "./levels.rb"

aws_access_key_id = 'AKIAIDGOVOANSDVRRO7Q'
aws_secret_access_key = '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'
endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'
region = 'us-east-1'


credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
@mturk = Aws::MTurk::Client.new(endpoint: endpoint, credentials: credentials, region: region)

# This will return $10,000.00 in the MTurk Developer Sandbox
puts @mturk.get_account_balance[:available_balance]

@level   = ARGV[0]
@version = ARGV[1]

if(!@level or !@version)
  puts "You must run this script with a level and version (e.g. Level-1 v2)"

  exit
end

def grade(hit)
   resp = @mturk.list_assignments_for_hit({
      hit_id: hit.hit_id, 
      max_results: 100,
      assignment_statuses: ["Approved","Rejected"], # accepts Submitted, Approved, Rejected
    })     

   hit_level = hit.title.split(":")[0]

   return if !hit.question.match(/SchemeVis\/#{@level}\/#{@version}/)

   answer_key = @levels[hit_level][:answers]

   assignment_datas = resp.assignments.map do |assignment|

     worker_id = assignment.worker_id
     worker_answers = assignment.answer.scan(/<QuestionIdentifier>q(\d+)<\/QuestionIdentifier>\n*<FreeText>(.+?)<\/FreeText>/).sort{|a,b| a[0].to_i - b[0].to_i}.map{|a| a[1]}
 
     score = 1.0 * worker_answers.zip(answer_key)
                                 .map{|f,s| f == s}
                                 .count(true) / answer_key.size 

     {worker_id: worker_id, score: score, answers: worker_answers, hit_id: assignment.hit_id, assignment_status: assignment.assignment_status, accept_time: assignment.accept_time, submit_time: assignment.submit_time } 
   end


   assignment_datas
end

def grade_assignment(assignment, answer_key)
end

resp = @mturk.list_hits({
  max_results: 100,
})

output = resp.hits.map{|hit| grade(hit)}.select{|x| x}.flatten.to_json

File.open("../data/#{@level}/#{@version}/responses.json", 'w') { |file| file.write(output) }


