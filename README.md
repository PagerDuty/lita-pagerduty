# lita-pagerduty

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
Lita pager note <incident ID> <content> - Add a note to a specific incident
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
Lita who's on call                      - Return the names of everyone currently on call
Lita pager identify <email address>     - Associate your chat user with your email address
Lita pager forget                       - Remove your chat user / email association
```

## License

[MIT](http://opensource.org/licenses/MIT)
