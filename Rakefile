require "html-proofer"

task :default do
    puts "Running CI tasks..."
    sh("JEKYLL_ENV=production bundle exec jekyll build")
    puts "Jekyll successfully built"

    puts "Running tests on generated HTML files"
    HTMLProofer.check_directory("./_site").run
    puts "HTML proofer passed"
    puts "Build completed"    
end