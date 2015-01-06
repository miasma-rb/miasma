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
being built around specific providers. The result is
a clean model interface providing consistency regardless
of the provider backend.

The "weight" of the library is kept light by using a
few simple approaches. All code is lazy loaded, so nothing
will be loaded into the runtime until it is actually required.
Dependencies are also kept very light, to reduce the number
of required libraries needing to be loaded. Parser wrapping
libraries are also used (`multi_json` and `multi_xml`) allowing
a choice of actual parsing backends in use. This removes
dependencies on nokogiri unless it's actually desired and
increases installation speeds.

## Features

### Thin Models

Thin models are a stripped down model that provides a subset
of information that an actual instance of the model may
contain. For instance, an `AutoScale::Group` may contain
a list of `Compute::Server`s. The collection provided within
the `AutoScale::Group` will be created via the resulting
API information on the group itself. However, since
we can provide expected mappings to what API provides
`Compute` and know these instances will be within the
`servers` collection, we can use the `#expand` helper to
automatically load the full instance:

```ruby
auto_scale = Miasma.api(:type => :auto_scale, :provider ...)
group = auto_scale.groups.first

# this list will provide the `ThinModel` instances:
p group.servers.all

# this list will provide the full instances:
p group.servers.all.map(&:expand)
```

### Automatic API switching

Resources within a specific provider can span multiple
API endpoints. To deal with this, the provider API
implemenetations provide an `#api_for` method which
will automatically build a new API instance. This
allows Miasma to hop APIs under the hood to expand
`ThinModels` as shown above.

## Current status

Miasma is currently under active development and is
in a beta state. Models are still being implemented
and spec coverage is following closely behind the
model completions.

### Currently Supported Providers

Coverage currently varies from provider to provider
based on functionality restrictions and in progress
implementation goals. The README on each library
should provide a simple feature matrix for a quick
check on support availability:

* [AWS](https://github.com/miasma-rb/miasma-aws)
* [Rackspace](https://github.com/miasma-rb/miasma-rackspace)
* [OpenStack](https://github.com/miasma-rb/miasma-open-stack)
* [Local](https://github.com/miasma-rb/miasma-local)

## Info

* Repository: https://github.com/miasma-rb/miasma
