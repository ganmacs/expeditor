require 'rystrix/rich_future'

module Rystrix
  class Command

    NotExecutedYetError = Object.new

    def initialize(opts = {}, &block)
      @future = RichFuture.new(&block)
    end

    def execute
      @future.execute
      self
    end

    def get
      raise NotExecutedYetError if not @future.executed?
      @future.get
    end
  end
end
