require "test_helper"
require "ostruct"

class UserTest < ActiveSupport::TestCase
  def setup
    @old_domain = ENV['GOOGLE_DOMAIN']
    ENV['GOOGLE_DOMAIN'] = 'example.com'
  end

  def teardown
    ENV['GOOGLE_DOMAIN'] = @old_domain
  end

  test "should not create user if email domain does not match" do
    auth = OpenStruct.new(
      provider: 'google_oauth2',
      uid: '123545',
      info: OpenStruct.new(
        email: 'test@another.com',
        name: 'Test User',
        image: 'http://example.com/image.jpg'
      )
    )

    user = User.from_google(auth)
    assert_nil user
  end

  test "should create user if email domain matches" do
    auth = OpenStruct.new(
      provider: 'google_oauth2',
      uid: '123545',
      info: OpenStruct.new(
        email: 'test@example.com',
        name: 'Test User',
        image: 'http://example.com/image.jpg'
      )
    )

    user = User.from_google(auth)
    assert user.persisted?
    assert_equal user.email, 'test@example.com'
    assert_equal user.full_name, 'Test User'
    assert_equal user.avatar_url, 'http://example.com/image.jpg'
  end
end
