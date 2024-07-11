ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# UMD Customization
# Require minitest Mock functionality
require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'
# End UMD Customization

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # UMD Customization
    # Default user for testing has Admin privileges
    DEFAULT_TEST_USER = 'test_admin'

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:cas] = {
      provider: 'cas',
      uid: DEFAULT_TEST_USER
    }

    def cas_login(cas_directory_id)
      OmniAuth.config.mock_auth[:cas] = {
        provider: 'cas',
        uid: cas_directory_id
      }

      get '/auth/cas/callback'
    end

    def mock_cas_login(cas_directory_id)
      OmniAuth.config.mock_auth[:cas] = {
        provider: 'cas',
        uid: cas_directory_id
      }
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:cas]
      CasAuthentication.sign_in(cas_directory_id, session, cookies)
    end

    def mock_cas_login_for_integration_tests(cas_directory_id)
      allow(CasUser)
        .to receive(:find_or_create_from_auth_hash)
        .with(anything)
        .and_return(CasUser.find_by(cas_directory_id: cas_directory_id))

      cas_login(cas_directory_id)
    end

    def mock_cas_logout
      request.env.delete('omniauth.auth')
      CasAuthentication.sign_out(session, cookies)
    end

    # Runs the contents of a block using the given user as the current_user.
    def impersonate_as_user(user) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      current_admin_user = CasUser.find_by(cas_directory_id: session[:cas_user])
      session[:admin_id] = current_admin_user.id
      # session[:cas_user] = user.cas_directory_id
      CasAuthentication.sign_in(user.cas_directory_id, session, cookies)

      begin
        yield
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise e
      ensure
        # Restore fake user
        CasAuthentication.sign_in(CasUser.find(session[:admin_id]).cas_directory_id, session, cookies)
        # session[:cas_user] = CasUser.find(session[:admin_id]).cas_directory_id
        session.delete(:admin_id)
      end
    end

    # Runs the contents of a block using the given user as the current_user.
    def run_as_user(user)
      mock_cas_login(user.cas_directory_id)

      begin
        yield
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise e
      ensure
        # Restore fake user
        mock_cas_login(DEFAULT_TEST_USER)
      end
    end
    # End UMD Customization
  end
end

# UMD Customization

# Allows a constant defined in config/initializers to be be overridden for
# a single test, and then restored
def with_constant(constant_name, value)
  old_value = Rails.const_get(constant_name)
  silence_warnings do # Silence warning about redefining constant
    Object.const_set(constant_name, value)
  end

  yield

  silence_warnings do
    Object.const_set(constant_name, old_value)
  end
end

# End UMD Customization