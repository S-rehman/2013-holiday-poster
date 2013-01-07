require 'rubygems'

desc "Completely empty /build"
task :clobber do
  sh "rm -rf build/* build/.[Dh]*"
  # sh "rm -rf build/*"
end

desc "Export compiled build"
task :build do
  # Double up on the build to avoid SASS errors after the first one - aluikart 2011-08-09 
  sh "bundle exec middleman build"
end

desc "Deply"
task :deploy => [:clobber, :build] do
  servers = %w{thirteen23.com}
  servers.each do |server|
    puts "Deploying app to #{server}"
    system("cd build;rsync -rltvz -e ssh . thirteen23@#{server}:/home/thirteen23/2013.poster.thirteen23.com")
    # system("ssh root@#{server} chown -R www-data:www-data /var/www/webapp/")
    # system("ssh root@server /etc/init.d/apache2 reload")
  end
end
