require 'sinatra'
require 'sinatra/reloader' if development? # gem install sinatra-contrib
require 'slim'
require './users'
#require './tracking'
require 'bcrypt'
require 'zip'
require 'csv'

configure do
  enable :sessions
  set :username, 'tester'
  # created via BCrypt::Password.create('test') in the rubymine terminal
  #test is the password, and tester is the username
  set :password, BCrypt::Password.new("$2a$10$/E7Lh5R/o8JAuEGoD6kwZ.iEIuyjfTqiOXBDG0vti96GmPwtwngUK")
end

get '/' do
  erb :homepage
end

get '/login' do
  erb :login
end

post '/login' do
  result = User.first(:username => params[:username], :password => params[:password])
  unless result == nil
    result2 = User.first(:username => params[:username], :password => params[:password], :role => "student")
    result3 = User.first(:username => params[:username], :password => params[:password], :role => "instructor/ta")
    if result3 != nil
      session[:admin] = true
      redirect to('/admin')
    elsif result2 != nil
      session[:student] = true
      redirect to('/vote')
    end
  end
  #User.create(username: "test", password: "test", role: "tester", choice1: "test1",  choice2: "test2",  choice3: "test3")
  slim :login
end

get '/logout' do
  session.clear
  redirect to('/')
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
#as well as http://www.wooptoot.com/file-upload-with-sinatra
#Load webpage with buttons for uploading .csv and .zip files
get "/admin" do
  if session[:admin]
    erb :uploader
  else
    redirect to('/notallowed')
  end
end

get '/csvupload' do
  erb :csvup
end

post '/csvupload' do
  #For .csv, upload as-is to project root directory
  nameoffile = params['csv'][:filename]
  if nameoffile.end_with? '.csv'
    File.open(params['csv'][:filename], 'w') do |f|
      f.write(params['csv'][:tempfile].read)
    end
    #User.create(username: "test", password: "test", role: "tester", choice1: "test1",  choice2: "test2",  choice3: "test3")
    File.open(nameoffile, "r") do |f|
      f.each_line do |line|
        array = line.split(',')
        User.create(username: array[0], password: array[1], role: array[2], choice1: "",  choice2: "",  choice3: "")
      end
    end
    redirect to('/success')
  end
  redirect to('/false')
end

post '/zipupload' do
  nameoffile = params['zip'][:filename]
  if nameoffile.end_with? '.zip'
    File.open(params['zip'][:filename], 'w') do |f|
      f.write(params['zip'][:tempfile].read)
    end
    redirect to('/success')
  end
  redirect to('/false')
end

get '/success' do
  erb :success
end

get '/false' do
  erb :false
end

get "/vote" do
  if $voter.voted
    redirect to('/thanks')
  end
  @site_url = @sites[ $voter.siteThis ]
  @disable_picks = (not $voter.siteSeen.all?).to_s
  @num_sites = $voters.numSites
  @siteNum = $voter.randomSiteIndex
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
  $voter.choice1 = @sites[ $voter.randomSite[ params[:first] - 1 ]]
  $voter.choice2 = @sites[ $voter.randomSite[ params[:second] - 1 ]]
  $voter.choice3 = @sites[ $voter.randomSite[ params[:third] - 1 ]]
  if vote( $voters, settings.username )
    redirect to('/thanks')
  else
    puts "Error: voting not successful"
  end
end

get "/thanks" do
  erb :thanks
end

#From the sinatra readme
#Download csv of voter results
get '/download' do 
  winners = makeWinnersHash( @sites )
  filename = 'voting_report.csv'
  makeWinnersCsv( winners, filename )  
  send_file filename
end

