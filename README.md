# spandx/rubygems

This project generates an index of every gem on rubygems.org and it's equivalent software licenses.
This index is meant to speed up license scanning for the `spandx` CLI.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spandx-rubygems'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install spandx-rubygems

## Usage

This will download each weekly backup from https://rubygems.org/pages/data,
restore it to a local postgresql database mounted in `./db/data`,
then generate a in memory hash to finally flush it to `rubygems.index` using
message pack.

You will need to have ruby and postgres installed.

```bash
$ ./bin/db-setup
$ ./bin/server
$ bundle exec ruby ./exe/spandx-rubygems update
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mokhan/spandx-rubygems.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
