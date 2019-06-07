# Limeade

Ruby interface to the LimeSurvey RemoteControl 2 API

LimeSurvey provides an API for accessing and managing surveys. The current version is RemoteControl 2.
It is exposed as a XML-RPC/JSON-RPC based web service. This gem accesses using JSON-RPC.

The goal of this gem is to access the API in a manner that is natural to rubyists. The API is defined in
terms of methods and arguments. That's easy to mimic in Ruby by means of `#method_missing`. Thus, call any
of the API's methods on the Limeade client itself!

This gem handles the API session transparently so you don't have to even think about it.

> __Note__ that before using the LimeSurvey RemoteControl API you need to activate it for your account. 
See [the manual](https://manual.limesurvey.org/RemoteControl_2_API#How_to_configure_LSRC2) for 
instructions on how to do this. Be sure to choose the **JSON-RPC** option.

> __Note__ also that you must activate a survey in order for it to be visible via the API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'limeade'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install limeade

## Usage

Start by requiring limeade into your code.

``` ruby
require 'limeade'
```

Instantiate a client and start invoking API methods on it. The API methods are documented
 [here](https://api.limesurvey.org/classes/remotecontrol_handle.html).

```ruby
client = Limeade::Client.new(api_uri, username, password)
surveys = client.list_surveys
summary = client.get_summary(surveys.first['sid'])
```

You'll probably want to get `api_uri`, `username`, and `password` from environment variables.

The responses from the API are parsed from JSON into Ruby objects. Bear in mind that `Hash` keys are
 going to be `String`.

When you are done accessing the API, it is polite to disconnect.
```ruby
client.disconnect
```
 
## Development

After checking out the repo, run `bin/setup` to install dependencies.

The specs rely on API location and credentials being defined as environment variables. Edit `bin/env.sh`
for your situation, then execute it.

    $ source bin/env.sh

Then run the tests.

    $ bundle exec rake spec

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the `.gem` file to
 [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dpellegrini/limeade. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Limeade project’s codebases, issue trackers, chat rooms and mailing lists is
expected to follow the [code of conduct](https://github.com/[USERNAME]/limeade/blob/master/CODE_OF_CONDUCT.md).
