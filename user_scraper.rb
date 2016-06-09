require 'rubygems'
require 'mini_magick'
require 'mechanize'
require 'logger'

class Users
  @logger = Logger.new(STDOUT)
  @config = YAML.load(IO.read("config_web.yml"))
  @agent = Mechanize.new
  @agent.read_timeout = 10000 #seconds
  @filename = 'output/output.json'
  @job_titles = [
    'lektor',
    'mitarbeiter',
    'assistent',
    'administrator',
    'leiter',
    'tutor',
    'koordinator',
    'referent',
    'techniker',
    'rektor',
    'betreuer',
    'führer',
    'manager',
    'bibliothekar',
    'grafiker',
    'jurist',
    'rezeptionist',
    'buchhalter',
    'verrechner'
  ]
#   'engineer'?
#   'lehrling'?
# 'reinigungskraft'?

def self.login()
    # simulate login to receive session
    login_config = @config['login']
    page = @agent.get(login_config['login_page'])
    form = page.forms.first
    form['j_username'] = login_config['user']
    form['j_password'] = login_config['password']
    page = form.submit

    form = page.forms.first
    form.submit

    @logger.info('login successful')
  end

  def self.scrape_user_data()
    @logger.info('start scraping user data. (this may take a while)')

    # scrapes html data of full user list
    user_config = @config['user']
    @users = @agent.post(user_config['user_page'], {
      "feld" => user_config['feld'],
      "methode" => user_config['methode'],
      "suchbegriff" => user_config['suchbegriff'],
      "aktion" => user_config['aktion'],
      "pagePath" => user_config['pagePath']
      })

    @logger.info('user data scraped sucessfully')
    # @users.save!('output.html')
  end

  def self.parse_users()
    data = @users.parser.css('table.formborder tr')
    data_ammount = data.count - 1

    data.each_with_index do |tr, idx|
      # bash feedback
      system('clear')
      @logger.info("User #{idx} / #{data_ammount} saved to #{@filename}")

      # skip first tr element (headline)
      next if (tr == @users.parser.css('table.formborder tr')[0])

      # skip all inaktive users
      next if (tr.css('td')[3].text == "")

      # vars
      id = tr.css('td a').to_s[39...-17] # profil_id
      surname = tr.css('td')[0].text.to_s # surname
      forename = tr.css('td')[1].text.to_s # forename
      function = tr.css('td')[2].text.to_s # function
      type = tr.css('td')[3].text.to_s # type
      sex = scrape_profil_sex(function, type) # sex
      image_id, mail, course = scrape_profil_data(id) # image_id, mail, course

      # save to output (json)
      File.open(@filename, 'a') do |file| 
        file << (
          "{\n"\
          "\"index\": #{idx},\n"\
          "\"fhs\": \"#{id}\",\n"\
          "\"forename\": \"#{forename}\",\n"\
          "\"surname\": \"#{surname}\",\n"\
          "\"function\": \"#{function}\",\n"\
          "\"type\": \"#{type}\",\n"\
          "\"mail\": \"#{mail}\",\n"\
          "\"course\": \"#{course}\",\n"\
          "\"sex\": \"#{sex}\",\n"\
          "\"image_id\": \"#{image_id}\"\n"\
          "},\n"\
          )
      end
      
    end
  end

  def self.scrape_profil_data(id)
    profil_config = @config['profil']
    profil = @agent.post(profil_config['profil_page'], {
     "pagePath" => profil_config['profil_page'],
     "aktion" => profil_config['aktion'],
     "edvUsername" => id,
     "feld" => profil_config['feld'],
     "methode" => profil_config['methode'],
     "suchbegriff" => profil_config['suchbegriff']
     })

    begin
      # image id
      image_id = profil.parser.css('table.formborder img')[1].to_s[49...-38]

      # mail
      mail_raw = profil.parser.css('table.formborder table tr td[2]').to_s.split('@')
      mail = mail_raw[0].split()[-1]
      if mail == "</td>" then mail = nil else mail += '@fh-salzburg.ac.at' end

      # studiengang
      course = profil.search("//table[@class='formborder']")[1].text.split().last

      # image
      if image_id && image_id != ""
        image = @agent.get("#{profil_config['image_page']}#{image_id}")

        if image.response['content-length'].to_i > 1
          image.save!("img/#{id}.jpeg")

          # convert image
          convert = MiniMagick::Tool::Mogrify.new
          convert.resize '100x110^'
          convert.gravity 'North' # NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast
          convert.crop '100x100+0+10'
          convert << "img/#{id}.jpeg"
          convert.call
        end
      end

      # return values
      [nil_to_string(image_id), nil_to_string(mail), nil_to_string(course)]

    rescue
      ["0", "0", "0"]
    end
  end

  def self.scrape_profil_sex(function, type)
    if (type == "Studierende")
      return "female"
    elsif (type == "Studierender")
      return "male"
    else
      function.downcase!

      @job_titles.each do |title_male|
        title_female = "#{title_male}in"
        if function.include? title_female
          return "female"
        elsif function.include? title_male
          return "male"
        end
      end
      return "w/s"
    end
  end

  def self.clear_output_file
    File.open(@filename, 'w') do |file| 
      file.truncate(0)
    end
  end

  def self.nil_to_string(value)
    if (!value || value == "") then "0" else value end
  end

  # start scraping
  clear_output_file()
  login() 
  scrape_user_data()
  parse_users()
end