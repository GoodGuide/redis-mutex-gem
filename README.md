# RedisMutex

[![Build Status](https://travis-ci.org/GoodGuide/redis_mutex.svg?branch=master)](https://travis-ci.org/GoodGuide/redis_mutex)

This gem provides very simple distributed pessimistic locking using Redis.

It provides no API, at present, for a blocking lock operation. For our purposes, we don't require blocking, as we're using this within a Sidekiq work fetcher, which already has polling semantics (and in which the order of fetchers attempting to lock isn't important).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_mutex'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_mutex

## Usage

TODO: Write usage instructions here

## Contributing

1. [Fork it](https://github.com/GoodGuide/redis_mutex/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
