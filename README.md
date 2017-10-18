# markov_twitter

#### setup: _installation_

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

#### setup: _twitter integration_

The source code of the gem (available on github
[here](http://github.com/maxpleaner/markov_twitter))
includes a `.env.example` file which includes two environment variables.
Both of them need to be changed to the values provided by Twitter.
To get these credentials, create an application on the Twitter developer
console. Then create a file identical to `.env.example` but named `.env`
in the root of your project, and add the credentials there.
This file is automatically read by the gem.

The two environment variables that are needed are
`TWITTER_API_KEY` and `TWITTER_SECRET_KEY`. They can be set on a
per-invocation basis using the [env](https://ss64.com/bash/env.html) command
in bash, e.g.:

```sh
env TWITTER_API_KEY=foo TWITTER_SECRET_KEY=bar ruby script.rb
```

Note that the callback URL or any of the OAuth stuff on the Twitter dev
console is unnecessary. Specifically this requires only 
[application-only authentication](https://developer.twitter.com/en/docs/basics/authentication/overview/application-only).

#### usage: _TweetReader_

First, initialize a [MarkovTwitter::Authenticator](DOCS_PATH/MarkovTwitter/Authenticator):

```rb
authenticator = MarkovTwitter::Authenticator.new(
  api_key: ENV.fetch("TWITTER_API_KEY"),
  secret_key: ENV.fetch("TWITTER_SECRET_KEY")
)
```

Then initialize [MarkovTwitter::TweetReader](DOCS_PATH/MarkovTwitter/TweetReader):

```rb
tweet_reader = MarkovTwitter::TweetReader.new(
  client: authenticator.client
)
```

Lastly, fetch some tweets for an arbitrary username. Note that the
[get_tweets](DOCS_PATH/MarkovTwitter/TweetReader:get_tweets) method will return
the most recently 20 tweets only. This gem doesn't have a way to fetch more
tweets than that.

```rb
tweets = tweet_reader.get_tweets(username: "@accidental575")
puts tweets.map(&:text).first # the newest
# => "Jets fan who stands for /\nnational anthem sits on /\nAmerican flag /\n#accidentalhaiku by @Deadspin \nhttps://t.co/INsLlMB31G"
```

#### usage: _MarkovBuilder_

[MarkovTwitter::MarkovBuilder](DOCS_PATH/MarkovTwitter/MarkovBuilder) gets
passed the list of tweet strings to its initialize:

```rb
chain = MarkovTwitter::MarkovBuilder.new(
  phrases: tweets.map(&:text)
)
```

The linkages between words are automatically created and it's 
possible to evaluate the chain right away, producing a randomly
generated sentence. There are three built in methods to 
evaluate the chain, but more can be constructed using lower-level methods.
There are two ways these methods differ:

a. do they build the result by walking along the :next or :prev nodes
(forward or backward?)
b. How do they pick the first node, and how do they choose a node
when there are no more linkages along the given direction (:prev or :next)?

Here are those three methods:

1. [evaluate](DOCS_PATH/MarkovTwitter/MarkovBuilder:evaluate) - navigates
the chain along the :next linkage (left to right) and picks a completely random
node to start with and when stuck

    ```rb
    5.times.map  { chain.evaluage length: 10 }
    # => [
    #   "by @FlayrahNews https://t.co/LbxzPQ5Zqv back. / together with dung! / American",
    #   "thought/ #accidentalhaiku by @news_24_365 https://t.co/kkfz5S3Kut pumpkin / Wes Anderson's Isle",
    #   "has been in a lot about / #accidentalhaiku by @UrbanLion_",
    #   "them, my boyfriend used my friends. Or as / #accidentalhaiku",
    #   "25 years... / feeling it today. / to write /"
    # ]
    ```

2. [evaluate_favoring_end](DOCS_PATH/MarkovTwitter/MarkovBuilder:evaluate_favoring_end)
- navigates the chain along the :prev linkage (right to left). To pick the starting
node or a new node when stuck, picks a random one that has no :next linkage
(it is at the end of the phrase)

    ```rb
    5.times.map  { chain.evaluage_favoring_end length: 10 }
    # => [
    #   "by @FlayrahNews https://t.co/LbxzPQ5Zqv back. / together with dung! / American",
    #   "thought/ #accidentalhaiku by @news_24_365 https://t.co/kkfz5S3Kut pumpkin / Wes Anderson's Isle",
    #   "has been in a lot about / #accidentalhaiku by @UrbanLion_",
    #   "them, my boyfriend used my friends. Or as / #accidentalhaiku",
    #   "25 years... / feeling it today. / to write /"
    # ]
    ```

