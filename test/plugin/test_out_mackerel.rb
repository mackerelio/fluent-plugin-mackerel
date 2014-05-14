require 'helper'

class MackerelOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::MackerelOutput, tag).configure(conf)
  end

  def test_configure
  end


end