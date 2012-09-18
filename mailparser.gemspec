Gem::Specification.new do |spec|
  spec.authors = 'TOMITA Masahiro'
  spec.email = 'tommy@tmtm.org'
  spec.files = ['README.md'] + Dir.glob('lib/**/*.rb')
  spec.homepage = 'http://github.com/tmtm/mailparser'
  spec.license = 'Ruby\'s'
  spec.name = 'mailparser'
  spec.summary = 'Mail Parser'
  spec.description = 'MailParser is a parser for mail message'
  spec.test_files = Dir.glob(['test.rb', 'test/**/test_*.rb'])
  spec.version = '0.5.0.beta2'
  spec.add_dependency 'mmapscanner'
end
