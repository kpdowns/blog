# Blog
A repository containing all code and content for my personal blog. Made with inspiration from the [Jekyll Cayman theme](https://github.com/pietromenna/jekyll-cayman-theme) provided under the Creative Commons license. Styles and general details were modified. Please see [here](https://creativecommons.org/licenses/by/4.0/) for the license under which this was acquired.

## Pre-requisites
* Jekyll
* Ruby version > 2.00
* WinSCP for deployment
* Environment variables set with deployment credentials

## Building and serving the site

To install dependencies for the blog run `bundler install`.

Use `jekyll build` to build the site. `jekyll serve` is used to serve the site locally from a development server. 

To deploy to [https://www.kevindowns.co.za](https://www.kevindowns.co.za) run `deploy.bat`. This will build the site and deploy using FTP where the credentials and details are stored in local environment variables.