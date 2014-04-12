# lita-pagerduty

[![Build Status](https://img.shields.io/travis/esigler/lita-pagerduty/master.svg)](https://travis-ci.org/esigler/lita-pagerduty)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)
[![RubyGems :: RMuh Gem Version](http://img.shields.io/gem/v/lita-pagerduty.svg)](https://rubygems.org/gems/lita-pagerduty)
[![Coveralls Coverage](https://img.shields.io/coveralls/esigler/lita-pagerduty/master.svg)](https://coveralls.io/r/esigler/lita-pagerduty)
[![Code Climate](https://img.shields.io/codeclimate/github/esigler/lita-pagerduty.svg)](https://codeclimate.com/github/esigler/lita-pagerduty)
[![Gemnasium](https://img.shields.io/gemnasium/esigler/lita-pagerduty.svg)](https://gemnasium.com/esigler/lita-pagerduty)

PagerDuty (http://pagerduty.com) handler for checking who's on call, scheduling, ack, resolve, etc.

## Installation

Add lita-pagerduty to your Lita instance's Gemfile:

``` ruby
gem "lita-pagerduty"
```

## Configuration

Add the following variables to your Lita config file:

``` ruby
config.handlers.pagerduty.api_key   = ''
config.handlers.pagerduty.subdomain = ''
```

## Usage

### Specific incidents

```
Lita pager incidents all                - Show all open incidents
Lita pager incidents mine               - Show all open incidents assigned to me
Lita pager incident <incident ID>       - Show a specific incident
```

### Incident notes

```
Lita pager notes <incident ID>          - Show all notes for a specific incident
```

### Acknowledging an incident

```
Lita pager ack all                      - Acknowledge all triggered incidents
Lita pager ack mine                     - Acknowledge all triggered incidents assigned to me
Lita pager ack <incident ID>            - Acknowledge a specific incident
```

### Resolving an incident

```
Lita pager resolve all                  - Resolve all triggered incidents
Lita pager resolve mine                 - Resolve all triggered incidents assigned to me
Lita pager resolve <incident ID>        - Resolve a specific incident
```

### Misc

```
Lita pager identify <email address>     - Associate your chat user with your email address
Lita pager forget                       - Remove your chat user / email association
```

## License

[MIT](http://opensource.org/licenses/MIT)
