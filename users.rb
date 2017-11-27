require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  property :id, Serial #required for a database, wasn't specified in class
  property :username, String
  property :password, String
  property :role, String
end

DataMapper.finalize()

#User.create(username: "test", password: "test", role: "tester")
