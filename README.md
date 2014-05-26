# fluent-plugin-mackerel [![Build Status](https://travis-ci.org/tksmd/fluent-plugin-mackerel.png?branch=master)](https://travis-ci.org/tksmd/fluent-plugin-mackerel)

## Overview

[Fluentd](http://fluentd.org) plugin to send metrics to [mackerel.io](http://mackerel.io/).

## Installation

Install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-mackerel

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-mackerel
```

## Configuration

### Usage

This plugin uses [APIv0](http://help-ja.mackerel.io/entry/spec/api/v0) of mackerel.io.
```
<match ...>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_prefix custom.http_status
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```
When metrics_prefix doesn't start with "custom.", "custom." is automatically appended at its beginning.

Then the sent metric data will look like this:
```
{
  "hostId": "xyz",
  "name": "custom.http_status.2xx_count",
  "time": 1399997498,
  "value": 100.0
}
```
As shown above, metric name will be a concatenation of `metrics_prefix` and `out_keys` values.

`flush_interval` is not allowed to set less than 60 secs not to send API requests more than once in a minute.

## TODO

Pull requests are very welcome!!

## For developers

You have to run the command below when starting development.
```
$ bundle install --path vendor/bundle
```

To run tests, do the following.
```
$ VERBOSE=1 bundle exec rake test
```

When releasing, call rake release as follows.
```
$ bundle exec rake release
```

## Copyright

* Copyright (c) 2014- Takashi Someda ([@tksmd](http://twitter.com/tksmd/))
* Apache License, Version 2.0
