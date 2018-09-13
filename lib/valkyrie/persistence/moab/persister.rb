# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class Persister

    attr_reader :adapter

    delegate :storage_roots, :storage_trunk, to: :adapter

    def initialize(adapter:)
      @adapter = adapter

      ::Moab::Config.storage_roots = storage_roots
      ::Moab::Config.storage_trunk = storage_trunk

      storage_roots.each { |root| FileUtils.mkpath(File.join(root, storage_trunk)) }
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
      storage_roots.each do |root|
        FileUtils.remove_dir(File.join(root, storage_trunk, '.'), true)
      end
    end

    private

      def repository(resources)
        Repository.new(
          adapter: adapter,
          resources: resources,
        )
      end

  end
end
