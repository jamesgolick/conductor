# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_conductor_session',
  :secret      => '10d83b32e9e656fd73cab018e85a5678e11558e3e89cf2764b984e0888d92075b85a1972878a50d1d4015ae6cb8d9ac3b6f8209e352631cba97e968f03fc5125'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
