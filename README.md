## markov_twitter

---

### setup

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

#### twitter integration

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

### usage

#### TweetReader

First, initialize an [Authenticator](TODO):

