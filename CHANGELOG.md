# v0.2.36
* Refactor abstract model specs

# v0.2.34
* Remove deprecated method usage on http library

# v0.2.32
* Add API stub for after setup modifications (#17)
* Allow Server attributes to be lazy loaded

# v0.2.30
* Provide interface for API implementations to customize retry behavior

# v0.2.28
* Include original exception information on API load failures
* Provide better retry functionality on non-modify requests

# v0.2.26
* Update Collection#get to not match name if nil

# v0.2.24
* Add support for `http_proxy`, `https_proxy`, and `no_proxy` (#11)
* Use common helper modules for bogo library (#10)

# v0.2.22
* Fix lazy attribute loading on subclasses

# v0.2.20
* Add scrubbing response prior to parsing to prevent XML related errors
* Stub credentials if none are provided
* Add setup stub to allow implementations an entry point for custom behavior
* Add container attribute for unsupported attributes within model
* Provide better error output when loading fails

# v0.2.18
* Fix constant name used for retry interval (#9)
* Provide better automatic conversion of response body
* Update size limits for storage files

# v0.2.16
* Add `:unknown` as allowed state value for orchestration stacks
* Add load balancer attribute for instance states
* Add thin model for load balancer instance states

# v0.2.14
* Add non-response failure retry support on non-modify requests

# v0.2.12
* Extract provider implementations to standalone libraries
* Add test helper executable
* Update API body extraction to retype Array contents
* Add streamable helper for consistent storage file read

# V0.2.10
* Add auto-follow to paginated results on aws
* Speed up stack list building on aws

# v0.2.8
* Allow multiple expected response codes
* Fix API type provided when building server instance from ASG
* Remove automatic key sorting on Smash conversions
* Allow name based matching for data loading within AWS orchestration

# v0.2.6
* Add default filter implementation on collection
* Allow disable of automatic body extraction
* Always return streamish object store file body

# v0.2.4
* Make `Storage::File#body` setup provider responsibility
* Fix module usage within RS to properly squash existing methods
* Allow RS identity to be shared where applicable
* Fix creation time attribute population of stacks within OpenStack provider

# v0.2.2
* Add support for pre-signed AWS URLs
* Add `#url` method to `Storage::File` model
* Relax content-type checks on response for more reliable auto-parse (#2)
* Basic abstract spec coverage on storage
* Fix response body result by adding streaming detection

# v0.2.0
* Add initial OpenStack provider support
* Refactor of Rackspace provider support (build off OpenStack)
* Finish defining storage modeling interfaces
* Add initial storage provider implementation (AWS)

# v0.1.0
* Initial release
