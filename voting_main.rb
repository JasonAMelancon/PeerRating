require 'sinatra'
require 'sinatra/reloader' if development? # gem install sinatra-contrib
require 'slim'
require './users'
require './tracking'
require 'bcrypt'
require 'zip'
require 'csv'

=begin
configure do
  enable :sessions, :static
  set :username, 'tester'
  set :public_folder, $sitesDir
  # created via BCrypt::Password.create('test') in the rubymine terminal
  #test is the password, and tester is the username
  set :password, BCrypt::Password.new("$2a$10$/E7Lh5R/o8JAuEGoD6kwZ.iEIuyjfTqiOXBDG0vti96GmPwtwngUK")
end
=end
enable :sessions, :static
set :username, 'tester'
# set :public_folder, $sitesDir
# created via BCrypt::Password.create('test') in the rubymine terminal
#test is the password, and tester is the username
set :password, BCrypt::Password.new("$2a$10$/E7Lh5R/o8JAuEGoD6kwZ.iEIuyjfTqiOXBDG0vti96GmPwtwngUK")

get '/' do
  erb :homepage
end

get '/login' do
  erb :login
end

post '/login' do
  result = User.first(:username => params[:username], :password => params[:password])
  unless result == nil
    #puts "[user found...]"
    #result2 = User.first(:username => params[:username], :password => params[:password], :role => "student")
    #result3 = User.first(:username => params[:username], :password => params[:password], :role => "admin")
    session[:username] = result.username.strip
    if result.role.strip == "admin"
      session[:admin] = true
      redirect to('/admin')
    elsif result.role.strip == "student"
      session[:admin] = false
      $voter = $voters[ result.username.strip ]
      redirect to('/vote')
    end
  end
  #User.create(username: "test", password: "test", role: "tester", choice1: "test1",  choice2: "test2",  choice3: "test3")
  erb :notallowed # username/password not found
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

  Zip::ZipFile.open(file) do |zip_file|
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
    if $csvfilename    
      @insert = getInsert($sitesDir + '/' + $csvfilename)
      $csvfilename = nil
    else
      @insert = ""
    end
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
        array = line.chomp.split(',')
        User.create(username: array[0], password: array[1], role: array[2], choice1: "",  choice2: "",  choice3: "")
      end
    end
    $voters = hashify_voters()
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
    extract_zip(nameoffile, '.')
    $sites = arrayify_sites()
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
  @sites = $sites
  # puts "$sites dir = #{$sitesDir}"
  # puts "@sites = #{@sites}"
  # puts "$voter = #{$voter}"
  # puts "$voter.siteThis = #{$voter.siteThis}"
  @site_url = $sitesDir + "/" + @sites[ $voter.siteThis ] + "/index.html"
  @num_sites = $voter.numSites
  @siteNum = $voter.randomSiteIndex
  $voter.saw
  @disable_picks = ( $voter.siteSeen.all? ) ? ( "" ) : ( "disabled" )
  erb :vote, :layout => false
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
  $voter.choice1 = $sites[ $voter.randomSite[ params[:first].to_i - 1 ]]
  $voter.choice2 = $sites[ $voter.randomSite[ params[:second].to_i - 1 ]]
  $voter.choice3 = $sites[ $voter.randomSite[ params[:third].to_i - 1 ]]
  if vote( $voters, session[:username] )
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
post '/csvdownload' do 
  winners = makeWinnersHash( $sites )
  $csvfilename = 'voting_report.csv'
  makeWinnersCsv( winners, $csvfilename )  
  redirect to('/admin')
end

=begin
get '*' do
  #puts "params: #{params['splat']}"
  filename = params['splat'][0] # + "index.html" 
  #puts "filename: #{filename}"
  if File.exist? filename
    send_file filename
  end
end
=end

