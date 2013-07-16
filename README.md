# MobileTechnics SMS API Client

Unofficial ruby adapter for MobileTechnics HTTP Bulk SMS API. Tries to mimick
mail API, so users can switch e.g. ActionMailer with this SMS provider. Requires
Ruby 1.9.

## Installation

Add this line to your application's Gemfile:

    gem 'mote_sms'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mote_sms

## Usage

```ruby
# Using global transport (quick and dirty)
MoteSMS.transport = MoteSMS::MobileTechnicsTransport.new 'https://endpoint.com:1234', 'username', 'password'
sms = MoteSMS::Message.new do
 to '+41 79 111 22 33'
 from 'ARUBYGEM'
 body 'Hello world, you know.'
end
sms.deliver
```

```ruby
# Using client instance
transport = MoteSMS::MobileTechnicsTransport.new 'https://endpoint.com:1234', 'username', 'password'
sms = MoteSMS::Message.new do
  # create message
end
sms.deliver(transport: transport)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
