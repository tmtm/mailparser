Gem::Specification.new do |spec|
  spec.authors = 'TOMITA Masahiro'
  spec.email = 'tommy@tmtm.org'
  spec.files = ['README.txt', 'HISTORY'] + Dir.glob('lib/**/*.rb')
  spec.homepage = 'http://github.com/tmtm/mailparser'
  spec.license = 'Ruby\'s'
  spec.name = 'mailparser'
  spec.summary = 'Mail Parser'
  spec.test_files = Dir.glob(['test.rb', 'test/**/test_*.rb'])
  spec.version = '0.4.22'
end
