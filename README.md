### FH Salzburg User Scraper
- The FH Salzburg User Scraper is a ruby based webscraper of the FHSYS (FH web interface for students and employees).
- With the scraper you can get the following data as JSON:
- fhs number, forename, function, type, mail, course, sex, image_id
- Additionaly you will get thumbnail images of the users


### Setup
- Create 'config_web.yml' file (you can edit the 'config_web_sample.yml').
- Enter your fh-username and fh-password in the login scetion of 'config_web.yaml'.
- bundle install

### Requirements
-  The script requires [minimagick](https://github.com/minimagick/minimagick "A ruby wrapper for ImageMagick or GraphicsMagick command line.")
-  To run minimagick ImageMagick or GraphicsMagick command-line tool has to be installed.

### Author
- Josef Krabath - MMT-B2014
