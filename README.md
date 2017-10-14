## markov_twitter

---

1. Setup
  a. [installation](#installation)
  b. [twitter integration](#twitter_integration)
2. Usage
  a. [TweetReader](#tweet_reader)
  b. [MarkovBuilder](#markov_builder)
3. Internals
  a. [application structure](#application_structure)
  b. [tests](#tests)

---

### setup

<a name="installation" />

#### installation

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

<a name="twitter_integration">

#### twitter integration

The source code of the gem (available on github
[here](http://github.com/maxpleaner/markov_twitter)])
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

### usage

<a name="tweet_reader"></a>

#### TweetReader


First, initialize an [Authenticator](TODO):

