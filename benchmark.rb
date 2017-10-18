require 'benchmark'
require 'markov_twitter'
require 'pry'

txt                = nil
phrases            = nil
chain              = nil
random_results     = nil
favor_next_results = nil
favor_prev_results = nil

Benchmark.bm do |bench|
  
  bench.report("loading the text into memory                  ") do
    txt = File.read "spec/mobydick.txt"
    phrases = txt.split(/^\s*$/)
  end
  
  bench.report("adding the text to a markov chain             ") do
    chain = MarkovTwitter::MarkovBuilder.new phrases: phrases
  end
  
  bench.report("evaluating 10k words with random evaluator    ") do
    random_results = chain.evaluate length: 10_000
  end
  
  bench.report("evaluating 10k words with favor_next evaluator") do
    favor_next_results = chain.evaluate_favoring_start length: 10_000    
  end
  
  bench.report("evaluating 10k words with favor_prev evaluator") do
    favor_prev_results = chain.evaluate_favoring_end length: 10_000
  end

end

a = chain.evaluate length: 200
b = chain.evaluate_favoring_start length: 200
c = chain.evaluate_favoring_end length: 200
binding.pry
false
