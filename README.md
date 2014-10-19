```
 ███▄ ▄███▓ ██▓ ▄▄▄        ██████  ███▄ ▄███▓ ▄▄▄
▓██▒▀█▀ ██▒▓██▒▒████▄    ▒██    ▒ ▓██▒▀█▀ ██▒▒████▄
▓██    ▓██░▒██▒▒██  ▀█▄  ░ ▓██▄   ▓██    ▓██░▒██  ▀█▄
▒██    ▒██ ░██░░██▄▄▄▄██   ▒   ██▒▒██    ▒██ ░██▄▄▄▄██
▒██▒   ░██▒░██░ ▓█   ▓██▒▒██████▒▒▒██▒   ░██▒ ▓█   ▓██▒
░ ▒░   ░  ░░▓   ▒▒   ▓▒█░▒ ▒▓▒ ▒ ░░ ▒░   ░  ░ ▒▒   ▓▒█░
░  ░      ░ ▒ ░  ▒   ▒▒ ░░ ░▒  ░ ░░  ░      ░  ▒   ▒▒ ░
░      ░    ▒ ░  ░   ▒   ░  ░  ░  ░      ░     ░   ▒
       ░    ░        ░  ░      ░         ░         ░  ░
```

## Overview

Miasma is YACACL (Yet Another Cloud API Client Library). Instead of
attempting to cover all the functionalities of all the different
cloud and virt APIs, miasma is focused on providing a common modeling
that will "just work". This means there may be many things that seem
to be missing, but that's probably okay. Consistency is more important
than overall completeness. Miasma isn't trying to be a replacement
for libraries like fog, rather it's attempting to supplement those
libraries by providing a consistent modeling API.

## Usage

### Example

Lets have a look at using the compute model:

```ruby
compute = Miasma.api(
  :type => :compute,
  :provider => :aws,
  :credentials => {
    :aws_secret_access_key => 'SECRET',
    :aws_access_key_id => 'KEY_ID',
    :aws_region => 'us-west-2'
  }
)
```

With this we can now list existing servers:

```ruby
compute.servers.all
```

This will provide an array of `Miasma::Models::Compute::Server`
instances. It will also cache the result so subsequent calls
will not require another API call. The list can be refreshed
by requesting a reload:

```ruby
compute.servers.reload
```

## Info

* Repository: https://github.com/chrisroberts/miasma
