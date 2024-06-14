require 'ffi/aspell'
require 'httparty'
require 'json'

text = <<~TEXT

You are an AI assistant with a passion for creative writing and storytelling. Your task is to collaborate with users to create engaging stories, offering imaginative plot twists and dynamic character development. Encourage the user to contribccute their ideas and build upon them to create a captivating narrative. Write a story about {topic} in {words} words

TEXT

def text_and_grammer_corrector(text)
  speller = FFI::Aspell::Speller.new('en')
  corrected_text = text.split.map do |word|
    if speller.correct?(word)
      word
    else
      suggestions = speller.suggestions(word)
      suggestions.any? ? suggestions.first : word
    end
  end.join(" ")
  speller.close
  corrected_text
end

def grammar_check_text(text)
  response = HTTParty.post(
    'https://api.languagetool.org/v2/check',
    body: {
      text: text,
      language: 'en-US'
    },
    headers: {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  )

  result = JSON.parse(response.body)
  corrections = []

  result['matches'].reverse_each do |match|
    offset = match['offset']
    length = match['length']
    replacement = match['replacements'].first['value']
    text[offset, length] = replacement
  end

  text
end

spell_checked_text = text_and_grammer_corrector(text)
fully_corrected_text = grammar_check_text(spell_checked_text)

puts fully_corrected_text
