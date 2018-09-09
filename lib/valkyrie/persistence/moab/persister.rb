# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  require 'valkyrie/persistence/moab/repository'
  class Persister

    attr_reader :adapter

    delegate :resource_factory, :storage_roots, :storage_trunk, to: :adapter

    def initialize(adapter:)
      @adapter = adapter
    end

    # (see Valkyrie::Persistence::Memory::Persister#save)
    def save(resource:)
      repository([resource]).persist.first
    end

    # (see Valkyrie::Persistence::Memory::Persister#save_all)
    def save_all(resources:)
      repository(resources).persist
    rescue Valkyrie::Persistence::StaleObjectError
      # Re-raising with no error message to prevent confusion
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    # (see Valkyrie::Persistence::Memory::Persister#delete)
    def delete(resource:)
      repository([resource]).delete.first
    end
  
    def wipe!
      ::Moab::Config.storage_roots.each { |root| FileUtils.rm_rf(File.join(root, ::Moab::Config.storage_trunk)) }
    end

    def repository(resources)
      Valkyrie::Persistence::Moab::Repository.new(
        resources: resources,
        resource_factory: resource_factory,
        storage_roots: storage_roots,
        storage_trunk: storage_trunk
      )
    end
  end
end
