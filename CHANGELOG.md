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
