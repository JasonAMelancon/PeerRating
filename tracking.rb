require './users'

$sitesDir = "public"

$sitesDir = "." if $sitesDir == ""

# search through sub-directories of given directory full of student sites
# return an array of directory names
def arrayify_sites()
  if not Dir.exist? $sitesDir
    puts "Error: sites directory name (in tracking.rb) does not exist"
    return
  end
  siteArray = Array.new
  # go to pwd/dir
  Dir.chdir($sitesDir) { siteArray = Dir.glob("*").select {|x| Dir.exist? x }}
  # go back to parent dir
  siteArray
end

class Voter
  attr_accessor :randomSite, :randomSiteIndex, :siteSeen, :choice1,
    :choice2, :choice3, :voted

  @@numSites = Dir.chdir($sitesDir) { Dir.glob("*").select{ |x| Dir.exist? x }.size }
  def self.numSites
    @@numSites
  end
  def numSites
    @@numSites
  end
  def initialize()
    @randomSite = (0..@@numSites-1).to_a.shuffle
    @randomSiteIndex = 0
    @siteSeen = Array.new(@@numSites, false) # vote only if @siteSeen.all?
    # once these three strings are non-empty, the user can vote and commit
    # these strings to the database. A user can only vote if these database
    # fields are not nil.
    @choice1 = ""
    @choice2 = ""
    @choice3 = ""
    @voted = false
  end
  # these return an index into sites array
  def siteThis()
    @randomSite[ @randomSiteIndex ]
  end
  def siteNext()
    @randomSiteIndex = ( @randomSiteIndex + 1 ) % @@numSites
    @randomSite[ @randomSiteIndex ]
  end
  def sitePrev()
    @randomSiteIndex = ( @randomSiteIndex - 1 ) % @@numSites
    @randomSite[ @randomSiteIndex ]
  end
  def saw()
    @siteSeen[ @randomSiteIndex ] = true
  end
end

# returns a hash of all voters
def hashify_voters()
  voters = Hash.new
  student_records = User.all(:role => "student")
  #puts student_records
  student_records.each do |record|
    #puts record
    voters[ record.username.strip ] = Voter.new
  end
  voters
end

# puts user's choices in the database; returns true on success
def vote( voters_hash, username )
  user_record = User.get( username )
  if user_record == nil
    puts "Error [tracking.rb vote()]: user does not exist"
    return false
  end
  # check database to be sure the fields are blank
  check = user_record[ :choice1 ]
  return false if check != nil and check != ""
  # check to be sure user has not voted already -- done in /vote verb
  # check to be sure user has seen all sites
  voterObj = voters_hash[ username ]
  return false if not voterObj.siteSeen.all?
  # check to be sure user has selected all 3 favorites
  choice_not_made =
    voterObj.choice1.strip == "" or
    voterObj.choice2.strip == "" or
    voterObj.choice3.strip == ""
  return false if choice_not_made
  # go ahead and put the values in the database
  voterObj.voted = true
  user_record[ :choice1 ] = voterObj.choice1
  user_record[ :choice2 ] = voterObj.choice2
  user_record[ :choice3 ] = voterObj.choice3
  user_record.save
end

def makeWinnersHash( siteArray )
  winnersHash = Hash.new
  siteArray.each do |name|
    winnersHash[ name ] = 0 
  end
  ratersInDb = User.all( :role => "student" )
  ratersInDb.each do |rater|
    site1 = rater.choice1.strip
    next if site1 == nil || site1 == ""
    site2 = rater.choice2.strip
    site3 = rater.choice3.strip
    site1oldScore = winnersHash[ site1 ]
    site2oldScore = winnersHash[ site2 ]
    site3oldScore = winnersHash[ site3 ]
    winnersHash[ site1 ] = site1oldScore + 5
    winnersHash[ site2 ] = site2oldScore + 3
    winnersHash[ site3 ] = site3oldScore + 1
  end
  winnersHash
end

def makeWinnersCsv( winnersHash, voteFilename )
  f = File.new( $sitesDir + '/' + voteFilename, "w+" )
  winnersHash.each_key do |key|
    f.write( "#{key}, #{winnersHash[ key ]}\n" )
  end
  f.close
end

def getInsert( filename )
"<a href=\"#{filename}\" >winners</a>"
end
