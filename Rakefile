require "html-proofer"
require "rake/contrib/ftptools"

task :default do
    puts "Running CI tasks..."
    sh("JEKYLL_ENV=production bundle exec jekyll build")
    puts "Jekyll successfully built"

    puts "Running tests on generated HTML files"
    HTMLProofer.check_directory("./_site").run
    puts "Build completed"
    
    puts "Uploading _site to server"
    Dir.chdir('_site') do
        Rake::FtpUploader.connect('/', ENV['FTP_HOST'], ENV['FTP_USER'], ENV['FTP_PASS']) do |ftp|
            ftp.verbose = true # gives you some output
            ftp.upload_files("./**/*")
        end
    end
    puts "Successfully deployed site to server"
end