# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_railsspec_session',
  :secret      => '5747e2944d0dd91e26cd79f076efbe2bd975faee856f877292697c6d7a88e592062bb5fb6bfdf6165cb37134b711554b77988ec015e59377d380b1b444363ce6'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
