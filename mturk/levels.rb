require "json"

@levels = lambda{|level|
  case level
  when "Level-1"
    lambda {|version|
       {qualification_id_to_award: "3F54WXCIFPPARYU5CMDXBH5YOVN65L",
       qualification_id_required: nil,
       answers: JSON.parse(`cat ../data/#{level}/#{version}/questions.json`).map{|q| q["correct_answer"]},
       img_url_prefix: "https://s3.amazonaws.com/thoughtstem.cms.dev/SchemeVis/Level-1/#{version}/"}
    }

  when "Level-2"
    lambda {|version|
       {qualification_id_to_award: "35NJKTSSL0ZLHRYQKXT30YPDMYUXZD",
       qualification_id_required: "3F54WXCIFPPARYU5CMDXBH5YOVN65L",
       answers: JSON.parse(`cat ../data/#{level}/#{version}/questions.json`).map{|q| q["correct_answer"]},
       img_url_prefix:"https://s3.amazonaws.com/thoughtstem.cms.dev/SchemeVis/Level-2/#{version}/"}
    }
  end
}

