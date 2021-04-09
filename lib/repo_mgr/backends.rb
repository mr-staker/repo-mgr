# frozen_string_literal: false

require_relative 'backends/deb'

module RepoMgr
  # factory loader for RepoMgr::Backend::Foo objects
  class Backends
    def self.load(backend, config)
      @obj ||= {}

      @obj[backend] ||= Object.const_get(
        "RepoMgr::Backend::#{backend.capitalize}"
      ).new(config)

      @obj[backend]
    end
  end
end
