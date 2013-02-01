require 'rubygems'

desc "Completely empty /build"
task :clobber do
  sh "rm -rf build/* build/.[Dh]*"
  # sh "rm -rf build/*"
end

desc "Export compiled build"
task :build do
  sh "bundle exec middleman build"
end

desc "Deply"
task :deploy => [:clobber, :build] do
  servers = %w{thirteen23.com}
  servers.each do |server|
    puts "Deploying app to #{server}"
    system("cd build;rsync -rltvz -e ssh . thirteen23@#{server}:/home/thirteen23/2013.poster.thirteen23.com")
  end
end
