require 'sinatra'
require 'sinatra/reloader' if development? # gem install sinatra-contrib
require 'slim'
require './users'
require './tracking'
require 'bcrypt'
require 'zip'

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
  erb :testlink
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
  if session[:admin]
    erb :logintest
  else
    redirect to('/notallowed')
  end
end

get '/notallowed' do
  erb :notallowed
end

#The following block of 12 lines is sourced from stackoverflow at:
#https://stackoverflow.com/questions/19754883/how-to-unzip-a-zip-file-containing-folders-and-files-in-rails-while-keeping-the
#Extraction function to pull files from uploaded zip folder
def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

#The following 23 lines of code are reappropriated from:
#https://gist.github.com/runemadsen/3905593#file-form-erb-L10
#Load webpage with buttons for uploading .csv and .zip files
get "/admin" do
  erb :uploader
end

post '/admin' do
  #For .csv, upload as-is to project root directory
  if params[:csv]
    filename = params[:file][:filename]
    file = params[:file][:tempfile]
    File.open("./#{filename}", 'wb') do |f| 
      f.write(file.read)
    end
    # TODO: put csv info into db
    $voters = hashify_voters()
  end
  #For .zip, upload and then use extract_zip function to unpack contents into project root directory
  if params[:zip]
    filename = params[:file][:filename]
    file = params[:file][:tempfile]
    File.open("./#{filename}", 'wb') do |f|
      f.write(file.read)
    end
    extract_zip("./#{filename}", "./")
  end
end

@sites = arrayify_sites()
$voter = $voters[ settings.username ]

get "/vote" do
  if $voter.voted
    redirect to('/thanks')
  end
  @site_url = @sites[ $voter.siteThis ]
  @disable_picks = (not $voter.siteSeen.all?).to_s
  @num_sites = $voters.numSites
  $voter.saw
  erb :vote
end

post "/prev" do
  $voter.sitePrev
  redirect to('/vote')
end

post "/next" do
  $voter.siteNext
  redirect to('/vote')
end

post "/vote" do
  $voter.choice1 = params[:first]
  $voter.choice2 = params[:second]
  $voter.choice3 = params[:third]
  if vote( $voters, settings.username )
    redirect to('/thanks')
  else
    puts "Error: voting not successful"
  end
end

get "/thanks"
  "Thanks for voting!"
end

#From the sinatra readme
#Download csv of voter results
get '/download' do 
  
  send_file 'voting_report.csv'
end

