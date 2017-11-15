require 'sinatra'
require 'sinatra/reloader' if development? # gem install sinatra-contrib
require 'slim'
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


__END__
@@homepage
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Web Site Voting</title>

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <!-- jQuery library -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
    <!-- Latest compiled JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

    <style>
        body{
            background-color: black;
            color: white;
        }
        .jumbotron{
            text-align: center;
            margin-bottom: 0px;
            background-position: 50% 95%;
            background-size: cover;
            background-repeat: no-repeat;
            background-color: lightblue;
            font-family: "Impact", Charcoal, sans-serif;
        }
        #subtext, #jumboheader{
            color: black;
            background-color: lightblue;
            text-align: center;
        }
        .title{
            text-align: center;
            font-family: "Impact", Charcoal, sans-serif;
        }
    </style>
</head>
<body>

<!--Jumbotron code-->
<div class="jumbotron">
    <h1 id="jumboheader">Vote for your favorite web site</h1>
    <p id="subtext">created by your classmates</p>
</div>

<nav class="navbar navbar-inverse">
    <div class="container-fluid">
        <div class="navbar-header">
            <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#myNavbar">
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
          <a class="navbar-brand" href="/">Menu</a>
        </div>
        <ul class="nav navbar-nav">
            <li><a href="/test">Test</a></li>
            <li><a href="/login">Login</a></li>
        </ul>
    </div>
</nav>

  <nav>
    <ul>
      <li><a href="/login">Login</a></li>

    </ul>
  </nav>

</body>
</html>