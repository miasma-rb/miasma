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

### Switching providers

Switching providers requires modification to the API parameters:

```ruby
compute = Miasma.api(
  :provider => :rackspace,
  :credentials => {
    :rackspace_username => 'USER',
    :rackspace_api_key => 'KEY',
    :rackspace_region => 'REGION'
  }
)
```

The `compute` API will act exactly the same as before, now using
Rackspace instead of AWS.

## Design Objectives

This library is following a few simple objectives:

* Light weight
* Consistent API

The availabile API is defined first via the models,
then concrete implementations are built via available
provider interfaces. This means the provider code is
structured to support the models instead of the models
being built around what specific providers may provide.

The "weight" of the library is kept light by using a
few simple approaches. All code is lazy loaded, so nothing
will be loaded into the runtime until it is actually required.
Dependencies are also kept very light, to reduce the number
of required libraries needing to be loaded. Parser wrapping
libraries are also used (`multi_json` and `multi_xml`) allowing
a choice of actual parsing backends in use. This removes
dependencies on nokogiri unless it's actually desired and
increases installation speeds.

## Info

* Repository: https://github.com/chrisroberts/miasma
