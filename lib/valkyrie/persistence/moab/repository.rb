# frozen_string_literal: true
require 'tempfile'

module Valkyrie::Persistence::Moab
  class Repository
    include Valkyrie::Moab

    attr_reader :resources, :resource_factory
    def initialize(resources:, resource_factory:, storage_roots:, storage_trunk:)
      @resources = resources
      @resource_factory = resource_factory

      ::Moab::Config.storage_roots = storage_roots
      ::Moab::Config.storage_trunk = storage_trunk

      storage_roots.each { |root| FileUtils.mkpath(File.join(root, storage_trunk)) }
    end

    def persist
      resources.map do |resource|
        generate_id(resource) if resource.id.blank?
        
        files = moab_files(resource)
        files.each do |entry|
          add_to_moab(resource.id.to_s, 'metadata', entry[:file], entry[:key])
          entry[:file].unlink
        end
        resource
      end
    end

    def delete
      
    end

    # return array of files to persist to moab
    # [{key: 'descMetadata.xml', file: file},...]
    def moab_files(resource)
      resource_factory.from_resource(resource: resource)
    end

    def generate_id(resource)
      Valkyrie.logger.warn "The Moab adapter is not meant to persist new resources, but is now generating an ID."
      resource.id = SecureRandom.uuid
    end
  end
end