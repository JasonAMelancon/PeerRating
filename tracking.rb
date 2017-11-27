require './users'

$sitesDir = "sites"

$sitesDir = "." if $sitesDir = ""

# search through sub-directories of given directory full of student sites
# return an array of directory names
def arrayify_sites()
  if not Dir.exist? $sitesDir do
    puts "Error: sites directory name (in tracking.rb) does not exist"
    return
  end
  siteArray = Array.new
  # go to pwd/dir
  Dir.chdir($sitesDir) { siteArray = Dir.glob("*").select {|x| Dir.exist? x }}
  # go back to parent dir
  siteArray
end

class Rater
  @@numSites = Dir.chdir($sitesDir) { Dir.glob("*").select{ |x| Dir.exist? x }.size }

  def initialize()
    @randomSite = (0..@@numSites-1).to_a.shuffle
    @randomSiteIndex = 0
    @siteSeen = Array.new(@@numSites, false) # vote only if @siteSeen.all?
    @choice1 = ""
    @choice2 = ""
    @choice3 = ""
  end
  # these return an index into sites array
  def siteThis() { @randomSite[ @randomSiteIndex ] }
  def siteNext() do
    @randomSiteIndex = ( @randomSiteIndex + 1 ) % @@numSites
    @randomSite[ @randomSiteIndex ]
  end
  def sitePrev() do
    @randomSiteIndex = ( @randomSiteIndex - 1 ) % @@numSites
    @randomSite[ @randomSiteIndex ]
  end
  def saw(i)
    @siteSeen[ i ] = true
  end
end

# returns a hash of all raters
def hashify_raters()
  raters = Hash.new
  User.all(:fields => :username).each {|username| raters[ username ] = Rater.new }
  raters
end
