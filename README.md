# Rackspace to Route 53
A generic migration script to migrate DNS records from Rackspace Cloud DNS to Amazon Route 53.

## Dependencies
- ruby
- fog

## Setup

- Copy `example-settings.yml` to `settings.yml`
- Add your Rackspace and AWS IAM keys to `settings.yml`
- Replace the list of example domains with the domains you want to migrate.

## Credits
- Heavily inspired by [this script](http://www.thattommyhall.com/2013/06/17/moving-dns-from-rackspace-to-amazon-route53/). 
- Bug fixes and configuration options sponsored by [Technocrat](http://www.technocrat.com.au).
