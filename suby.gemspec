Gem::Specification.new do |s|
  s.name = 'suby'
  s.summary = "Subtitles' downloader"
  s.description = "Find and download subtitles"
  s.author = 'eregon'

  s.files = Dir['bin/*'] + Dir['lib/**/*.rb'] + %w[.gitignore README.md suby.gemspec]
  s.executables = ['suby']

  s.version = '0.0.5'
end
