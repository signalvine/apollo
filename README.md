# Apollo

Apollo is a gem for interacting with remote hosts. Its based around the idea of an inventory defining the available
resources. So for this inventory:

```yaml
---
hosts:
  vagrant:
    ip: 192.168.100.4
    user: vagrant
```

You would be able to run an ssh command by running `cluster.run(:vagrant, '/bin/true')`. This is very much a work in
progress as I figure out what needs to be in here.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apollo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apollo

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/signalvine/apollo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
