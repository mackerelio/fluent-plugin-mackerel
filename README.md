# fluent-plugin-mackerel [![Build Status](https://travis-ci.org/tksmd/fluent-plugin-mackerel.png?branch=master)](https://travis-ci.org/tksmd/fluent-plugin-mackerel)

## Overview

[Fluentd](http://fluentd.org) plugin to send metrics to [mackerel.io](http://mackerel.io/).

This plugin includes two components, namely MackerelOutput and MackerelHostidTagOutput. The former is used to send metrics to mackerel and the latter is used to append mackerel hostid to tag or record.

## Installation

Install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-mackerel

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-mackerel
```

## Configuration

### MackerelOutput

This plugin uses [APIv0](http://help-ja.mackerel.io/entry/spec/api/v0) of mackerel.io.
```
<match ...>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_name http_status.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

Then the sent metric data will look like this:
```
{
  "hostId": "xyz",
  "name": "custom.http_status.2xx_count",
  "time": 1399997498,
  "value": 100.0
}
```
As shown above, `${out_key}` will be replaced with out_key like "2xx_count" when sending metrics.

You can use `${[n]}` for `mackerel_name` where `n` represents any decimal number including negative value,

```
<match mackerel.*>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_name ${[1]}.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

then it indicates the `n` the value of the array got by splitting the tag by `.` (dot) and get the following output when the tag is `mackerel.http_status`.
```
{
  "hostId": "xyz",
  "name": "custom.http_status.2xx_count",
  "time": 1399997498,
  "value": 100.0
}
```
"custom" will be appended to the `name` attribute before sending metrics to mackerel automatically.

You can also send ["service" metric](http://help-ja.mackerel.io/entry/spec/api/v0#service-metric-value-post) as follows.
```
<match ...>
  type mackerel
  api_key 123456
  service yourservice
  metrics_name http_status.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```
`flush_interval` is not allowed to set less than 60 secs not to send API requests more than once in a minute.

Since version 0.0.4, metrics_prefix was removed and you should use metrics_name instead.

### MackerelHostidTagOutput

If you want to add the hostid to the record with a certain key name, do the following.
```
<match ...>
  type mackerel_hostid_tag
  add_to record
  key_name mackerel_hostid
</match>
```
As shown above, key_name field is required. Supposed host_id is "xyz" and input is `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`, then you can get `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4, "mackerel_hostid"=>"xyz"}]`

To append hostid to the tag, you can simply configure "add_to" as "tag" like this.
```
<match ...>
  type mackerel_hostid_tag
  add_to tag
</match>
```
When input is `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`, then the output will be `["test.xyz", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`

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
