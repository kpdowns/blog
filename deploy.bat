@ECHO OFF

ECHO Rebuilding site
rmdir /s /q _site
SET "JEKYLL_ENV=production"
call jekyll build

ECHO Uploading to FTP
winscp.com /command "open ftp://%BlogUploadUsername%:%BlogUploadPassword%@ftp.kevindowns.co.za/" "synchronize remote _site public_html -delete -transfer=automatic" "exit"