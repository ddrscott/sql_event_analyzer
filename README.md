# Overview

Consume Rails SQL events and generates an HTML overview for the SQL utilization.

## Usage

### Around any calls
```ruby
SqlEventAnalyzer.start(name: 'report1') do
  # Some code that does a lot of SQL
end
```

### View the Results

A directory will be created at the root of the project directry from which Rails
is running. All results are contained there as HTML files. Open them in your
web browser.

```sh
find tmp/sql_event_analyzer/
open tmp/sql_event_analyzer/report1.html
```

### Around a Rails Controller
```ruby
class ApplicationController < ActionController::Base

  # @see http://guides.rubyonrails.org/action_controller_overview.html#after-filters-and-around-filters
  around_action :capture_sql_filter

  def capture_sql_filter(&block)
    stats_file_name = "#{params[:controller]}-#{params[:action]}"
    SqlEventAnalyzer.start(name: stats_file_name, &block)
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sql_event_analyzer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sql_event_analyzer


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ddrscott/sql_event_analyzer.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

