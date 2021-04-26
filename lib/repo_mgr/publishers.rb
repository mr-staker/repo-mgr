# frozen_string_literal: false

require_relative 'publishers/git'

module RepoMgr
  # factory loader for RepoMgr::Publisher::Foo objects
  class Publishers
    def self.load(publisher, config)
      @obj ||= {}

      @obj[publisher] ||= Object.const_get(
        "RepoMgr::Publisher::#{publisher.capitalize}"
      ).new(config)

      @obj[publisher]
    end
  end
end
