require "redis_mutex/version"
require 'securerandom'

class RedisMutex
  SCRIPTS = {}
  MutexNotLockedError = Class.new(StandardError)

  def self.def_redis_script(name, source)
    SCRIPTS[name] = {
      source: source,
      sha: Digest::SHA1.hexdigest(source),
    }
  end

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

  def_redis_script :compare_and_delete, <<-LUA
    if ARGV[1] ~= redis.call('get', KEYS[1]) then
      return false
    end

    return redis.call('del', KEYS[1])
  LUA
  def release
    run_script(:compare_and_delete, [key], [token]) or raise MutexNotLockedError
  end

  def_redis_script :compare_and_expire, <<-LUA
    if ARGV[1] ~= redis.call('get', KEYS[1]) then
      return false
    end

    return redis.call('expire', KEYS[1], ARGV[2])
  LUA
  def renew(expire)
    run_script(:compare_and_expire, [key], [token, expire]) or raise MutexNotLockedError
  end

  def_redis_script :compare_and_swap, <<-LUA
    if ARGV[1] ~= redis.call('get', KEYS[1]) then
      return false
    end

    return redis.call('set', KEYS[1], ARGV[2])
  LUA
  def set_token(new_token)
    run_script(:compare_and_swap, [key], [token, new_token]) or raise MutexNotLockedError
    @token = new_token
  end

  def locked?
    @redis.get(key) == token
  end

  def verify!
    locked? or raise MutexNotLockedError
  end

  private

  def run_script(name, keys, args)
    script = SCRIPTS.fetch(name)
    @redis.evalsha(script.fetch(:sha), keys, args)
  rescue Redis::CommandError
    @redis.eval(script.fetch(:source), keys, args)
  end
end
