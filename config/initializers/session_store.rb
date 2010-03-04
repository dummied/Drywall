# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_Drywall_session',
  :secret => 'c6269ffc2cb1d078a3abecfe85e0a7358b3d6cced620e6d92d972c2b746ce1480b6da7a7737f17948d8517afea7617a53cd352eaf3a792e84a09258b2f4f6fb5'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
