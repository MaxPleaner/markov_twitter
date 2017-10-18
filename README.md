# markov_twitter

## setup: _installation_

Either:

```sh
gem install markov_twitter
```

or add it to a Gemfile:

```rb
gem "markov_twitter"
```

After doing this, require it as usual:

```rb
require "markov_twitter"
```

## setup: _twitter integration_

The source code of the gem (available on github [here](http://github.com/maxpleaner/markov_twitter)) includes a `.env.example` file which includes two environment variables. Both of them need to be changed to the values provided by Twitter. To get these credentials, create an application on the Twitter developer console. Then create a file identical to `.env.example` but named `.env` in the root of your project, and add the credentials there. Finally, add the [dotenv](https://github.com/bkeepers/dotenv) gem and call `Dotenv.load` right afterward. 

The two environment variables that are needed are `TWITTER_API_KEY` and `TWITTER_SECRET_KEY`. They can alternatively be set on a per-invocation basis using the [env](https://ss64.com/bash/env.html) command in bash, e.g.:

```sh
env TWITTER_API_KEY=foo TWITTER_SECRET_KEY=bar ruby script.rb
```

Note that the callback URL or any of the OAuth stuff on the Twitter dev console is unnecessary. Specifically this requires only  [application-only authentication](https://developer.twitter.com/en/docs/basics/authentication/overview/application-only).

## usage: _TweetReader_

First, initialize a [MarkovTwitter::Authenticator](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/Authenticator):

```rb
authenticator = MarkovTwitter::Authenticator.new(
  api_key: ENV.fetch("TWITTER_API_KEY"),
  secret_key: ENV.fetch("TWITTER_SECRET_KEY")
)
```

Then initialize [MarkovTwitter::TweetReader](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/TweetReader):

```rb
tweet_reader = MarkovTwitter::TweetReader.new(
  client: authenticator.client
)
```

Lastly, fetch some tweets for an arbitrary username. Note that the [get_tweets](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/TweetReader:get_tweets) method will return the most recently 20 tweets only. This gem doesn't have a way to fetch more tweets than that.

```rb
tweets = tweet_reader.get_tweets(username: "@accidental575")
puts tweets.map(&:text).first # the newest
# => "Jets fan who stands for /\nnational anthem sits on /\nAmerican flag /\n#accidentalhaiku by @Deadspin \nhttps://t.co/INsLlMB31G"
```

## usage: _MarkovBuilder_

[MarkovTwitter::MarkovBuilder](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder) gets passed the list of tweet strings to its initialize:

```rb
chain = MarkovTwitter::MarkovBuilder.new(
  phrases: tweets.map(&:text)
)
```

It internally stores the words in a [#nodes](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:nodes) dict where keys are strings and values are [Node](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node) instances. A Node is created from each whitespace-separated entity. Punctuation is treated like any other non-whitespace character.

The linkages between words are automatically created ([Node#linkages](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:linkages)) and it's  possible to evaluate the chain right away, producing a randomly generated sentence. There are three built in methods to  evaluate the chain, but more can be constructed using lower-level methods. There are two ways these methods differ:

1. Do they build the result by walking along the :next or :prev nodes (forward or backward)?

2. How do they pick the first node, and how do they choose a node when there are no more linkages along the given direction (:prev or :next)?

Here are those three methods:

1. [evaluate](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:evaluate)  
  - traverses rightward along :next
  - when starting or stuck, picks any random word

    ```rb
    5.times.map  { chain.evaluate length: 10 }
    # => [
    # "by @FlayrahNews https://t.co/LbxzPQ5Zqv back. / together with dung! / American",
    # "thought/ #accidentalhaiku by @news_24_365 https://t.co/kkfz5S3Kut pumpkin / Wes Anderson's Isle",
    # "has been in a lot about / #accidentalhaiku by @UrbanLion_",c
    # "them, my boyfriend used my friends. Or as / #accidentalhaiku",
    # "25 years... / feeling it today. / to write /"
    # ]
    ```
2. [evaluate_favoring_end](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:evaluate_favoring_end)
  - traverses leftward along :prev
  - when starting or stuck, picks a word that was at the end of one of the original phrases.
  - reverses the result before returning

    ```rb
    5.times.map  { chain.evaluate_favoring_end length: 10 }
    # => [
    # "revolution / to improve care, / #accidentalhaiku by @Deadspin https://t.co/INsLlMB31G",
    # "to save the songs you thought/ #accidentalhaiku by @Mary_Mulan https://t.co/ixw2EQamHq",
    # "adventure / together with dung! / #accidentalhaiku by @Deadspin https://t.co/INsLlMB31G",
    # "harder / for / creativity? / #accidentalhaiku by @AlbertBrooks https://t.co/DzXbGeYh0Z",
    # "/ Asking for 25 years... / #accidentalhaiku by @StratfordON https://t.co/k81u693AbV"
    # ]
    ```
3. [evaluate_favoring_start](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:evaluate_favoring_start)
  - traverses rightward along :next
  - when starting or stuck, picks a word that was at the start of one of the original phrases.

    ```rb
    5.times.map { chain.evaluate_favoring_start length: 10 }
    # => [
    # "RT if you listened to / to get lost /",
    # "Jets fan who stands for / #accidentalhaiku by @theloniousdev https://t.co/6Rb5F8XySy   # ",
    # "The first trailer for / and never come back.    # /",
    # "Zooey Deschanel / and never come back. / house in   # ",
    # "Oh my friends. Or as / #accidentalhaiku by @timkaine https://t.co/4pgknpmom5   # "    
    # ]
    ```

Note that it is possible to manually change the lists of start nodes and end nodes using [MarkovBuilder#start_nodes](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:start_nodes) and [MarkovBuilder#end_nodes](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:end_nodes)

## advanced usage: _custom evaluator_

The three previously mentioned methods all use [_evaluate](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:_evaluate) under the hood. This method supports any permutation of the following keyword args (all except start_node and probability_bounds are required).

- **length**  
   number of nodes in the result
- **direction**  
  :next or :prev
- **start_node**  
  the node to use at the beginning
- **probability_bounds**  
  _Array<Int1,Int2>_ where _0 <= Int1 <= Int2 <= 100_  
  This is essentially used to "stack the dice", so to speak. Internally, smaller probabilities are checked first. So if A has 50% likelihood and B/C/D/E/F each have 10% likelihood, then B/C/D/E/F can be guaranted by using [0,50] as probability_bounds. This 'stacked' probability is applied any time the program chooses a :next or :prev option.
- **node_finder**  
  A lambda which gets run when the evaluator is starting or stuck. It gets passed random nodes one-by-one. The first one for which the block returns a truthy value is used.

Note that [_evaluate](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:_evaluate) returns nodes and so the values must be manually fetched and joined. Here's an example of providing a custom node_finder lambda so that all phrases in the result start with "the":

```rb
5.times.map do
  nodes = chain._evaluate(
    direction: :next,
    length: 10,
    node_finder: -> (node) {
      node.value.downcase == "the"
    }
  )
  nodes.map(&:value).join " "
end
# => [
# "the rain / #accidentalhaiku by @theloniousdev https://t.co/6Rb5F8XySy The first trailer",
# "The first trailer for / #accidentalhaiku by @shiku___ https://t.co/ZutjdsopAo the",
# "the songs you thought/ #accidentalhaiku by @Mary_Mulan https://t.co/ixw2EQamHq The first",
# "The first trailer for / #accidentalhaiku by @UrbanLion_ https://t.co/bvM6eeXGj5 The",
# "the rain / and start / I THOUGHT MY BOYFRIEND"
# ]
```

## advanced usage: _linkage manipulation_

There are manipulations available at the [Node](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node) level (accessible through the [MarkovBuilder#nodes](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder:nodes) dict). Keep in mind that there is only a single Node for each unique string. There can be many references to it from other nodes' linkages, but since there is still only a single object, each unique string only has a single set of :next and :previous linkages emanating from it. 

Although the core linkage data is accessible in [Node#linkages](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:linkages) and [Node#total_num_inputs](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:total_num_inputs), they should not be manipulated directly via these references. Rather, use one of the following methods which are automatically balancing in terms of keeping :next and :previous probabilities mirrored and ensuring that the probabilities sum to 1. That is to say, if I add _node1_ as the :next linkage of _node2_, then _node1_ will have its :prev probabilities balanced and _node2_ will have its :next probabilities balanced.

1. [#add_next_linkage(child_node)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:add_next_linkage)  
  adds a linkage in the :next direction or increases its likelihood
2. [#add_prev_linkage(parent_node)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:add_prev_linkage)  
  adds a linkage in the :prev direction or increases its likelihood
3. [#remove_next_linkage(child_node)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:remove_next_linkage)  
  removes a linkage in the :next direction or decreases its likelihood
4. [#remove_prev_linkage(parent_node)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:remove_prev_linkage)  
  removes a linkage in the :prev direction or decreases its likelihood
5. [#add_linkage!(direction, other_node, probability)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:add_linkage!)  
  Force-sets the probability of a linkage. Adjusts the other probabilities so they still sum to 1. 
6. [#remove_linkage!(direction, other_node)](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:remove_linkage!)  
  Completely removes a linkage as an option. Adjusts other probabilities so they still sum to 1.

All of these methods can be safely run many times. Note that `remove_next_linkage` and `remove_prev_linkage` do _not_ completely remove the node from the list of options. They just decrement its probability an amount determined by [Node#total_num_inputs](http://rubydoc.info/gems/markov_twitter/MarkovTwitter/MarkovBuilder/Node:total_num_inputs).

## development: code organization

The gem boilerplate was scaffolded using a gem I made, [gemmyrb](http://github.com/maxpleaner/gemmyrb). 

Test scripts are in the [spec/](http://github.com/maxpleaner/markov_twitter/tree/master/spec) folder, although some helper methods are written into the application code at [lib/markov_twitter/test_helper_methods.rb](http://github.com/maxpleaner/markov_twitter/tree/master/lib/markov_twitter/test_helper_methods.rb).

The application code is in [lib/](http://github.com/maxpleaner/markov_twitter/tree/lib).

Documentation is built with [yard](https://github.com/lsegal/yard) into [doc/](http://github.com/maxpleaner/markov_twitter/tree/master/doc) - it's viewable [on rubydoc](http://rubydoc.info/gems/markov_twitter). It has 100% documentation at time of writing. If when building, it shows that something is undocumented, run `yard --list-undoc` to find out where it is.

## development: tests

To run the tests, install markov_twitter with the development dependencies:

```rb
gem install markov_twitter --development
```

Then run `rspec` in the root of the repo.

There are 40 test cases at time of writing.

By default, Webmock will prevent any real HTTP calls for the twitter-related tests, but this can be disabled (and real Twitter data used) by running the test suite with an environment variable:

```sh
env DISABLE_WEBMOCK=true rspec
```

## development: todos

Things which would be interesting to add:

- dictionary-based search and replace
- part-of-speech-based search and replace

