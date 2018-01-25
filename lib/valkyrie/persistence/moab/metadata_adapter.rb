# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class MetadataAdapter
    attr_writer :storage_repository

    attr_reader :storage_roots, :storage_trunk

    def initialize(storage_roots:, storage_trunk:)
      @storage_roots = storage_roots
      @storage_trunk = storage_trunk
    end

    # @return [Valkyrie::Persistence::Moab::Persister] A Moab persister for
    #   this adapter.
    def persister
      Valkyrie::Persistence::Moab::Persister.new(adapter: self)
    end

    # @return [Valkyrie::Persistence::Moab::QueryService] A query service for
    #   this adapter.
    def query_service
      @query_service ||= Valkyrie::Persistence::Moab::QueryService.new(adapter: self)
    end

    def storage_repository
      @storage_repository ||= ::Moab::StorageRepository.new
    end

    def resource_factory
      Valkyrie::Persistence::Moab::ResourceFactory.new(adapter: self)
    end
  end
end