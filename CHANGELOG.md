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
