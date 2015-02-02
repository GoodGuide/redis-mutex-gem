require "minitest/autorun"
require 'redis_mutex'
require 'redis'

class TestRedisMutex < Minitest::Test
  def setup
    # NB: this test suite requires a redis server to be available. set ENV['REDIS_URL'] to change the default hostname/port
    @redis = Redis.new
    @redis.info # check if connection is working and die early if not

    @mutex_name = :test_mutex
    @mutex_a = RedisMutex.new(@redis, @mutex_name)
    @mutex_b = RedisMutex.new(@redis, @mutex_name, 'foo')
    @key = @mutex_a.key
    @redis.del(@key)
  end

  attr_reader :mutex_a, :mutex_b, :key, :redis, :mutex_name

  def teardown
    redis.del(key)
  end

  def test_acquire_lock_succeeds_when_unlocked
    assert mutex_a.acquire_lock(1)
    assert redis.get(key) == mutex_a.token
    assert redis.pttl(key) < 1000 # verify expiration was set
  end

  def test_acquire_lock_fails_when_locked
    mutex_a.acquire_lock(1)
    assert !mutex_b.acquire_lock(1)
    assert redis.get(key) == mutex_a.token
  end

  def test_locked_when_unlocked
    assert !mutex_a.locked?
  end

  def test_locked_when_locked
    mutex_a.acquire_lock(1)
    assert mutex_a.locked?
  end

  def test_release_succeeds_when_holding_lock
    mutex_a.acquire_lock(1)
    assert mutex_a.release
  end

  def test_release_fails_when_not_holding_lock
    mutex_a.acquire_lock(1)

    assert_raises(RedisMutex::MutexNotLockedError) do
      mutex_b.release
    end
  end

  def test_renew_succeeds_when_holding_lock
    mutex_a.acquire_lock(1)
    assert mutex_a.renew(10)
    assert redis.ttl(@key) > 9
  end

  def test_renew_fails_when_not_holding_lock
    mutex_a.acquire_lock(1)

    assert_raises(RedisMutex::MutexNotLockedError) do
      mutex_b.renew(10)
    end
  end

  def test_set_token_succeeds_when_holding_lock
    new_token = 'bar'

    mutex_a.acquire_lock(1)

    assert redis.get(key) == mutex_a.token
    assert mutex_a.set_token(new_token)
    assert redis.get(key) == new_token
    assert mutex_a.token == new_token
  end

  def test_set_token_fails_when_not_holding_lock
    mutex_a.acquire_lock(1)

    assert_raises(RedisMutex::MutexNotLockedError) do
      mutex_b.set_token('bar')
    end
  end

  def test_verify_succeeds_when_holding_lock
    mutex_a.acquire_lock(1)
    assert mutex_a.verify!
  end

  def test_verify_fails_when_not_holding_lock
    mutex_a.acquire_lock(1)

    assert_raises(RedisMutex::MutexNotLockedError) do
      mutex_b.verify!
    end
  end

  def test_handoff
    mutex_a.acquire_lock(1)

    assert RedisMutex.new(redis, mutex_name, mutex_a.token).release
  end

end
