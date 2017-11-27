require 'sinatra'
require 'sinatra/reloader' if development? # gem install sinatra-contrib
require 'slim'
require './users'
require './tracking'
require 'bcrypt'

configure do
  enable :sessions
  set :username, 'tester'
  #pull in from the csv for passwords and user
  # created via BCrypt::Password.create('test') in the rubymine terminal
  #test is the password, and tester is the username
  set :password, BCrypt::Password.new("$2a$10$/E7Lh5R/o8JAuEGoD6kwZ.iEIuyjfTqiOXBDG0vti96GmPwtwngUK")
end

get '/' do
  erb :homepage
end

get '/test' do
  output =<<EOS
<h1>Test link successful</h1>
  <p>Click 'Home' to go to the home page</p>
  <ul>
    <li><a href="/">Home</a></li>
  </ul>
EOS
  output
end

get '/login' do
  slim :login
end

post '/login' do
   #order matters since settings.password is a BCrypt::Password
  if settings.username == params[:username] && settings.password == params[:password]
    session[:admin] = true
#User.create(username: "test", password: "test", role: "tester", choice1: "test1",  choice2: "test2",  choice3: "test3")
    redirect to('/logintest')
  else
    slim :login
  end
end

get '/logout' do
  session.clear
  redirect to('/login')
end

get '/logintest' do
  'welcome to the login test zone'
end

get "/admin" do
  erb :uploader
end

post '/save_file' do
  filename = params[:file][:filename]
  file = params[:file][:tempfile]
  File.open("./Files/#{filename}", 'wb') do |f|
    f.write(file.read)
  end
end
