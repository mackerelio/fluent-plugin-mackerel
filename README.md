# fluent-plugin-mackerel [![Build Status](https://travis-ci.org/mackerelio/fluent-plugin-mackerel.png?branch=master)](https://travis-ci.org/mackerelio/fluent-plugin-mackerel)

## Overview

This is the plugin for sending metrics to [mackerel.io](http://mackerel.io/) using [Fluentd](http://fluentd.org).

This plugin includes two components, MackerelOutput and MackerelHostidTagOutput. The former is used to send metrics to Mackerel and the latter is used to append the Mackerel hostid for tagging or recording.

## Installation

Install with either the gem or fluent-gem command as shown:

```
# for fluentd
$ gem install fluent-plugin-mackerel

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-mackerel
```

## Configuration

### MackerelOutput

This plugin uses mackerel.io's [APIv0](http://help-ja.mackerel.io/entry/spec/api/v0).
```
<match ...>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_name http_status.${out_key}
  use_zero_for_empty
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

Metric data that has been sent will look like this:
```
{
  "hostId": "xyz",
  "name": "custom.http_status.2xx_count",
  "time": 1399997498,
  "value": 100.0
}
```
As shown above, `${out_key}` will be replaced with out_key like "2xx_count" when sending metrics.

In the case an outkey does not have any value, the value will be set to `0` with `use_zero_for_empty`, the default of which is true.
For example, if you have set `out_keys 2xx_count,3xx_count,4xx_count,5xx_count`, but only get `2xx_count`, `3xx_count` and `4xx_count`, then `5xx_count` will be set to `0` with `use_zero_for_empty`.

`out_key_pattern` can be used instead of `out_keys`. Input records whose keys match the pattern set to `out_key_pattern` will be sent. Either `out_keys` or `out_key_pattern` is required.

```
<match ...>
  type mackerel
  api_key 123456
  service yourservice
  metrics_name http_status.${out_key}
  out_key_pattern [2-5]xx_count
```

`${[n]}` can be used as a tag for `metrics_name` where `n` represents any decimal number including negative values.

```
<match mackerel.*>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_name ${[1]}.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

This indicates the value of the `n` th index of the array. By splitting the tag with a `.` (dot) the following output can be got when the tag is `mackerel.http_status`.
```
{
  "hostId": "xyz",
  "name": "custom.http_status.2xx_count",
  "time": 1399997498,
  "value": 100.0
}
```
"custom" will be automatically appended to the `name` attribute before sending metrics to mackerel.

You can also send [service metrics](http://help.mackerel.io/entry/spec/api/v0#service-metric-value-post) as shown.
```
<match ...>
  type mackerel
  api_key 123456
  service yourservice
  metrics_name http_status.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

When sending service metrics, the prefix "custom" can be removed with `remove_prefix` as follows.
This option is not availabe when sending host metrics.

```
<match ...>
  type mackerel
  api_key 123456
  service yourservice
  remove_prefix
  metrics_name http_status.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
</match>
```

`flush_interval` may not be set to less than 60 seconds so as not to send API requests more than once per minute.

This plugin overwrites the default values of `buffer_queue_limit` and `buffer_chunk_limit` as shown.

* buffer_queue_limit to 4096
* buffer_chunk_limit to 100K

Unless there is some particular reason to change these values, we suggest leaving them as is.

From version 0.0.4 and on, metrics_prefix has been removed and metrics_name should be used instead.

### MackerelHostidTagOutput

Let's say you want to add the hostid to the record with a specific key name...
```
<match ...>
  type mackerel_hostid_tag
  add_to record
  key_name mackerel_hostid
</match>
```
As shown above, the key_name field is required. For example if the host_id is "xyz" and input is `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`, you'll get `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4, "mackerel_hostid"=>"xyz"}]`

To append the hostid to the tag, you can simply configure "add_to" as "tag" like this.
```
<match ...>
  type mackerel_hostid_tag
  add_to tag
</match>
```
If the input is `["test", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`, then the output will be `["test.xyz", 1407650400, {"val1"=>1, "val2"=>2, "val3"=>3, "val4"=>4}]`

Both `add_prefix` and `remove_prefix` options are availale to control rebuilding tags.

## TODO

Pull requests are very welcome!!

## For developers

You'll need to run the command below when starting development.
```
$ bundle install --path vendor/bundle
```

To run tests...
```
$ VERBOSE=1 bundle exec rake test
```

If you want to run a certain file, run rake like this
```
$ VERBOSE=1 bundle exec rake test TEST=test/plugin/test_out_mackerel.rb
```

Additionally, you can run a specific method like this.
```
$ VERBOSE=1 bundle exec rake test TEST=test/plugin/test_out_mackerel.rb TESTOPTS="--name=test_configure"
```

When releasing, call rake release as shown.
```
$ bundle exec rake release
```

For debugging purposes, you can change the Mackerel endpoint with an `origin` parameter like this.
```
<match ...>
  type mackerel
  api_key 123456
  hostid xyz
  metrics_name http_status.${out_key}
  out_keys 2xx_count,3xx_count,4xx_count,5xx_count
  origin https://example.com
</match>
```

## References

* [Posting Service Metrics with fluentd](http://help.mackerel.io/entry/advanced/fluentd)
* [How to use fluent-plugin-mackerel (Japanese)](http://qiita.com/tksmd/items/1212331a5a18afe520df)

## Authors

- Takashi Someda ([@tksmd](http://twitter.com/tksmd/))
- Mackerel Development Team

## Copyright

* Copyright (c) 2014- Hatena Co., Ltd. and Authors
* Apache License, Version 2.0
