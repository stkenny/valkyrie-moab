 # frozen_string_literal: true
module Valkyrie::Persistence::Moab
class ORMConverter
    include Valkyrie::Moab

    attr_reader :object

    def initialize(object:)
      @object = object
    end

    def convert
      resource_klass.new(converted_attributes.merge(new_record: false))
    end

    private

    def converted_attributes
      @converted_attributes ||= Valkyrie::Persistence::Postgres::ORMConverter::RDFMetadata.new(attributes).result.symbolize_keys
    end

    def attributes
      @resource_metadata ||= JSON.parse(File.read(metadata_path))
    end

    def metadata_path
      find_moab_filepath(object.id, "#{object.id}.jsonld", 'metadata')
    rescue Valkyrie::StorageAdapter::FileNotFound
      raise Valkyrie::Persistence::ObjectNotFoundError
    end

    def internal_resource
      attributes["internal_resource"]
    end

    def resource_klass
      internal_resource.constantize
    end
  end
end
