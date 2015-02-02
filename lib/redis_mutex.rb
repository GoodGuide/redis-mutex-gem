require "redis_mutex/version"
require 'securerandom'

class RedisMutex
  SHAs = {}
  MutexNotLockedError = Class.new(StandardError)

  def initialize(redis, name, token=nil)
    @redis = redis
    @name = name
    @token = token || SecureRandom.base64(16)
  end

  def key
    ['mutex', @name].join(':')
  end

  attr_accessor :token

  # returns true if you got the lock, false otherwise
  def acquire_lock(expire)
    @redis.set(key, token, nx: true, ex: expire)
  end

  def release
    sha = SHAs[:delete_if_locked] ||= @redis.script(:load, <<-LUA)
      if ARGV[1] ~= redis.call('get', KEYS[1]) then
        return false
      end

      return redis.call('del', KEYS[1])
    LUA

    @redis.evalsha(sha, [key], [token]) or raise MutexNotLockedError
  end

  def renew(expire)
    sha = SHAs[:set_expiration_if_locked] ||= @redis.script(:load, <<-LUA)
      if ARGV[1] ~= redis.call('get', KEYS[1]) then
        return false
      end

      return redis.call('expire', KEYS[1], ARGV[2])
    LUA

    @redis.evalsha(sha, [key], [token, expire]) or raise MutexNotLockedError
  end

  def set_token(new_token)
    sha = SHAs[:compare_and_swap] ||= @redis.script(:load, <<-LUA)
      if ARGV[1] ~= redis.call('get', KEYS[1]) then
        return false
      end

      return redis.call('set', KEYS[1], ARGV[2])
    LUA

    @redis.evalsha(sha, [key], [token, new_token]) or raise MutexNotLockedError
    @token = new_token
  end

  def locked?
    @redis.get(key) == token
  end

  def verify!
    locked? or raise MutexNotLockedError
  end
end
