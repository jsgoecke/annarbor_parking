#Ann Arbor Parking Voice Service
#Inspired by http://www.voiptechchat.com/voip/218/use-asterisk-cepstral-and-perl-to-get-parking-and-weather-updates/
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uuidtools'

methods_for :dialplan do

  #Fetch the available parking spaces by scraping the Ann Arbor website
  def fetch_available_spaces
    doc = Hpricot(open(COMPONENTS.annarbor_parking[:url]))

    parking_spaces = Array.new
    cnt = 0
    (doc/"td").each do |row|
      if row.inner_text =~ /............................/
        parking_spaces[cnt].merge!( { :spaces => row.inner_text.gsub("............................  ", "") } )
        cnt += 1
      else
        parking_spaces[cnt] = { :name => row.inner_text }
      end
    end
    
    return parking_spaces
  end

  #Build the sound file using the TTS engine with a menu based on the data
  #retrieved in the fetch_available_spaces method
  def lot_details(parking_spaces)
    cnt = 1
    menu_message = "Welcome to the Ann Arbor parking information service."
    parking_spaces.each do |lot|
      menu_message = menu_message + 
                     " For " + 
                     lot[:name] +
                     " please press " +
                     cnt.to_s +
                     "."
      cnt += 1
    end
    filename = COMPONENTS.annarbor_parking[:sound_dir] + UUID.timestamp_create.to_s + ".ulaw"
    system("echo #{menu_message} | text2wave -o #{filename} -otype ulaw")
    return filename.gsub!(".ulaw", "")
  end
  
  #After the user has made a selection build the sound file that tells us how many
  #spaces there are
  def spaces_available(parking_spaces, lot)
    available_spaces_message = parking_spaces[lot.to_i - 1][:name] +
                               " has " +
                               parking_spaces[lot.to_i - 1][:spaces] +
                               " spaces available. Thank you for using our service. Goodbye."
    filename = COMPONENTS.annarbor_parking[:sound_dir] + UUID.timestamp_create.to_s + ".ulaw"
    system("echo #{available_spaces_message} | text2wave -o #{filename} -otype ulaw")
    return filename.gsub!(".ulaw", "")
  end
  
end