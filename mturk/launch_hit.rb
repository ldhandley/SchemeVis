require 'aws-sdk'
require 'erb'

require "./levels.rb"

aws_access_key_id = @aws_access_key_id
aws_secret_access_key = @aws_secret_access_key
endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'
region = 'us-east-1'

# Uncomment this line to use in production
# endpoint = 'https://mturk-requester.us-east-1.amazonaws.com'

credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
@mturk = Aws::MTurk::Client.new(endpoint: endpoint, credentials: credentials, region: region)

puts @mturk.get_account_balance[:available_balance]

@level   = ARGV[0]
@version = ARGV[1]

def generate_html(level)
  @img_url_prefix = @levels[level][@version][:img_url_prefix]

  renderer = ERB.new(`cat question_template.html.erb`)
  output = renderer.result()  


  puts output

  return output
end

def generate_qualifications(level)
 ret = []

 if(@levels[level][@version][:qualification_id_required])
    ret << {
              qualification_type_id: @levels[level][@version][:qualification_id_required], # required
              comparator: "Exists",
              required_to_preview: true,
            }
 end

 ret << {
          qualification_type_id: @levels[level][@version][:qualification_id_to_award], # required
          comparator: "DoesNotExist",
          required_to_preview: false,
        }

 ret
end

resp = @mturk.create_hit({
  max_assignments: 20,
  auto_approval_delay_in_seconds: 3*24*60*60, #3 days
  lifetime_in_seconds: 7*24*60*60, # required
  assignment_duration_in_seconds: 60*60, # required
  reward: "0.1", # required
  title: @level + ": Solve some puzzles" , # required
  keywords: "puzzle, test",
  description: "Solve these puzzles", # required
  question: generate_html(@level),
  qualification_requirements: generate_qualifications(@level),
})

puts resp

