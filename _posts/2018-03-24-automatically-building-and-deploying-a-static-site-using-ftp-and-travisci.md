---
layout: post
title:  "Automatically building and deploying Jekyll sites using FTP and Travis CI"
categories: ftp travis-ci how-to jekyll continuous-integration
comments: true
---

[Travis CI](https://travis-ci.org/) is a continuous integration service that can be set up to automatically build your code whenever you change a file. One of it's biggest draws, at least for me, is that it's free for open source projects (that means any publicly accessible repositories on GitHub). It's also relatively straightforward and powerful. Because of this, it allows for some interesting workflows.

When I first looked at building this blog, I decided I wanted an easy to maintain static HTML site. Building something using React or Angular with a database in the backend would be overkill for my needs. Therefore, I decided to go for Jekyll which is a static site generator that's built using Ruby. Additionally, I also decided to self-host. My hosting provider in this case only provided access via cPanel and FTP. Because no one wants to manually copy files over FTP (manual tasks are always more error-prone than scripted ones) I needed an easy way to script building and deployment. In comes Travis CI.

## Building Jekyll sites using Travis CI
The free version of Travis CI will only run builds on public repositories that you've enabled. Travis CI builds are defined by a `.travis.yml` file in the root of your repository - this file tells Travis CI what it needs to know to be able to build your project. Whenever you commit code to your repository it will automatically be picked up and built by Travis CI using the steps you've defined in your `.travis.yml` file so long as your repository is set up correctly in Travis CI. 

The `.travis.yml` file that's defined for this blog is:

```yaml
language: ruby
rvm:
- 2.4.2
install:
- bundle install
branches:
  only:
  - master
```

Because Jekyll is dependant on Ruby, we've defined that as the language to use in our `.travis.yml` file.

The **branches** section indicates that to Travis CI that it must only build commits on the **master** branch. This allows us to have a separate branch for draft posts and only push to **master** when we want the latest version of the posts to be compiled as static HTML and deployed.

As per their documentation,

 > The defaults for Ruby projects are `bundle install` to install dependencies, and `rake` to build the project.

That suits us just fine because we can use both `bundle` and `rake` to both build and deploy our site. 

When Travis CI runs the build, it will first execute `bundle install` to download all the gems (Ruby libraries) that the blog is dependant on. After that, Travis CI, by default, will execute Rake using the Rakefile defined in the root of the repository. By default, the **default** task in the Rakefile will be executed.

## Deploying Jekyll sites using FTP and Rake
**Rake** is a build utility that we can use to build Ruby projects and a **Rakefile** is a build file used by Rake that defines any number of tasks to be run. A minimal example of a Rakefile to build a Jekyll site in production mode is:

```ruby
task :default do    
    sh("JEKYLL_ENV=production bundle exec jekyll build")
end
```

For more detail on Rake I'd recommend reading some of the documentation hosted at [https://ruby.github.io/rake/](https://ruby.github.io/rake/).

In our case, when Travis CI builds the project, it would execute the **default** task defined above. The command being executed builds the site using Jekyll - this will generate the HTML for the site and place it in the `_site` folder. 

When it comes to deploying these files using FTP, there are a number of options that we could use. For example, there are Ruby's built-in FTP libraries. However, that would require what I believe to be a lot of code that we'd need to write to accomplish our goals. Additionally, there would also be error handling that we'd need to do. Alternatively, we could use a tool like [WinSCP](https://winscp.net/). WinSCP has excellent scripting functionality built-in. We could use this scripting functionality to connect to our server and synchronise the files we needed. However, this wouldn't work on Travis CI because it's a Windows tool and Travis CI uses Linux containers. As another alternative, Travis CI even has a section in their documentation related to deploying the results of builds using FTP and cURL (see [https://docs.travis-ci.com/user/deployment/custom/](https://docs.travis-ci.com/user/deployment/custom/)). However, there is another option. We can use built-in Rake functionality to deploy the files ourselves.

The option I chose to go for instead uses Rake to connect to the FTP server and upload the files as part of the build process. The class we'll be using is `Rake::FtpUploader`. That way, if a problem occurs as part of the deployment, it'll fail the build as well. I found the `FtpUploader` class to not have much documentation, but it is pretty straightforward to use. 

In order to use the `FtpUploader` class you'll first need to add the `rake-contrib` gem as a dependency in your Gemfile:

```ruby
gem 'rake-contrib'
```

The following line will then need to be added to the top of your Rakefile:

```ruby
require "rake/contrib/ftptools"
```

This adds the **ftptools**, defined in the **rake-contrib** library, as a dependency for our Rakefile to execute. Travis CI will download and install this before the build starts because it is defined in our Gemfile.

Finally, you can use the following snippet as part of a task in your Rakefile to connect to your FTP server and upload the generated files that were built as result of executing the `jekyll build` command:

```ruby
    Dir.chdir('_site') do
        Rake::FtpUploader.connect('/', ENV['FTP_HOST'], ENV['FTP_USER'], ENV['FTP_PASS']) do |ftp|
            ftp.verbose = true
            ftp.upload_files("./**/*")
        end
    end
```

The code above first changes the working directory of Rake to be the generated `_site` directory.  

Using `FtpUploader` a connection is then made to the server defined using environment variables that can be configured in Travis CI - see [Defining environment variables in Travis CI](#defining-environment-variables-in-travis-ci). We've used environment variables so as not to leak the credentials for the user account that has access to the server. It would be very bad practice to have the account credentials in plain-text on a publicly hosted repository.

Additionally, in the case above, I created a user on my server whose only purpose is to upload the files from Travis CI. This user only has access to the **public_html** folder. I consider it best practice to always provide access to only the resources that a user needs access to in order to perform their tasks. For example, in this case, it doesn't make sense for this account to be able to access the root of the server. An added benefit is that if the user's credentials were compromised, the account could simply be deleted and a new one created. This would not be easily achievable if the credentials were used for other tasks. A lesson here is to **always have different accounts for different purposes**.

Once the connection is made, because we've defined the file mask as `./**/*`, all files and sub-folders will be uploaded to the server.

## Defining environment variables in Travis CI
It is never a good idea to store credentials for servers in plain-text in a repository. Yet, despite this, there a huge number of repositories on GitHub where people have done just this. A [quick search](https://github.com/search?utf8=%E2%9C%93&q=remove+password&type=Commits) of GitHub commits reveals just how often passwords are removed from repositories. 

Luckily, Travis CI allows us to store environment variables that aren't publicly visible for use during our builds. To set these up, you can navigate to your repositories settings on Travis CI.

On this page, you'll see an **Environment Variables** section. 

![Environment variables in Travis CI]({{ "/assets/posts/deploying-using-ftp-and-travis/images/environment-variables.png" | absolute_url }})

In this section, you can configure key-value pairs that you can refer to in your Rakefile. By default, the values are not displayed in the build log. However, toggling **Display value in build log** to true will result in the values appearing in plain-text during the build process.

For example, you can see above that **FTP_HOST**, **FTP_PASS**, and **FTP_USER** are defined. These are the same environment variables used in the snippet above that are passed to `FtpUploader`. In this way, anyone who has access to the code in my Rakefile does not have access to the credentials for my FTP server.

## Closing thoughts
Using a tool such as Travis CI for building and deploying Jekyll sites is both easy and straightforward. Additionally, one of the biggest benefits is that it's free for open source projects. This makes it very attractive for simplifying our lives and learning a useful tool all at the same time. Instead of manually copying the files generated by Jekyll, an error-prone task, we can instead use functionality that's already part of a tool Travis CI is calling to do it for us. With this, there are some security concerns. But these would be the same regardless of how you would automate the deployment process. However, Travis CI makes it simple and secure by providing the ability to set private environment variables.

If you would like to view the source for this blog, along with all associated Travis CI configuration, feel free to view the repository on GitHub [here](https://github.com/kpdowns/blog).