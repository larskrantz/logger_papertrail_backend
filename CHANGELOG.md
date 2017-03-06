# Changelog
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.2] - 2017-03-06
### Changed
- Merged #7 squashing warnings from Elixir 1.4.
- Some module documentation

## [0.1.1] - 2016-10-24
### Changed
- Fixed issue #4, if DNS resolution fails (ip is resolved every 60s), it uses last successfully resolved ip.

## [0.1.0] - 2016-04-18
### Added
- Change Log
- Possibility to use `:url` to config log target. Format: `papertrail://<host>:<port>/<system_name>` instead of `:host` and `:system_name`

### Changed
- Always trims away leading `Elixir.` in module name (tag in [Papertrail](http://papertrailapp.com) semantic)
- Since [Papertrail](http://papertrailapp.com) tags has a limitation of 32 chars, `LoggerPapertrailBackend` will trim away module names from the start of the name, ie `This.Is.Ridiculously.Long.Module.Name` becomes `Is.Ridiculously.Long.Module.Name` in the logs.

## [0.2.0 / 0.1.0] - 2015-10-02
First stable releases.
