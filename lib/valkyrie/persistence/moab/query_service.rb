# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class QueryService
    attr_reader :adapter, :query_handlers
    delegate :repository, to: :adapter
    # @param adapter [Valkyrie::Persistence::Memory::MetadataAdapter] The adapter which
    #   has the cache to query.
    def initialize(adapter:)
      @adapter = adapter
      @query_handlers = []
    end

    # @param id [Valkyrie::ID] The ID to query for.
    # @raise [Valkyrie::Persistence::ObjectNotFoundError] Raised when the ID
    #   isn't in the persistence backend.
    # @return [Valkyrie::Resource] The object being searched for.
    def find_by(id:)
      validate_id(id)
      Valkyrie::Persistence::Moab::ORMConverter.new(object: id).convert || raise(::Valkyrie::Persistence::ObjectNotFoundError)
    end

    def find_many_by_ids(ids:)
      ids.map do |id|
        begin
          find_by(id: id)
        rescue ::Valkyrie::Persistence::ObjectNotFoundError
          nil
        end
      end.reject(&:nil?)
    end

    # @return [Array<Valkyrie::Resource>] All objects in the persistence backend.
    def find_all
      adapter.storage_object_paths.lazy.map do |storage_object_path|
        find_by(id: Valkyrie::ID.new(Pathname.new(storage_object_path).basename.to_s))
      end
    end

    # @param model [Class] Class to query for.
    # @return [Array<Valkyrie::Resource>] All objects in the persistence backend
    #   with the given class.
    def find_all_of_model(model:)

    end

    # @param resource [Valkyrie::Resource] Model whose members are being searched for.
    # @param model [Class] Class to query for. (optional)
    # @return [Array<Valkyrie::Resource>] child objects of type `model` referenced by
    #   `resource`'s `member_ids` method. Returned in order.
    def find_members(resource:, model: nil)
      find_references_by(resource: resource, property: :member_ids).select do |member|
        model.nil? || member.is_a?(model)
      end
    end

    # @param resource [Valkyrie::Resource] Model whose property is being searched.
    # @param property [Symbol] Property which, on the `resource`, contains {Valkyrie::ID}s which are
    #   to be de-referenced.
    # @return [Array<Valkyrie::Resource>] All objects which are referenced by the
    #   `property` property on `resource`. Not necessarily in order.
    def find_references_by(resource:, property:)
      ids = (resource.try(property) || []).select { |id| id.is_a?(Valkyrie::ID) }
      ids.lazy.map do |id|
        find_by(id: id)
      end
    end

    # @param resource [Valkyrie::Resource] The resource which is being referenced by
    #   other resources.
    # @param property [Symbol] The property which, on other resources, is
    #   referencing the given `resource`
    # @return [Array<Valkyrie::Resource>] All resources in the persistence backend
    #   which have the ID of the given `resource` in their `property` property. Not
    #   in order.
    def find_inverse_references_by(resource:, property:)
      find_all.select do |obj|
        begin
          Array.wrap(obj[property]).include?(resource.id)
        rescue
          false
        end
      end
    end

    # @param resource [Valkyrie::Resource] The resource whose parents are being searched
    #   for.
    # @return [Array<Valkyrie::Resource>] All resources which are parents of the given
    #   `resource`. This means the resource's `id` appears in their `member_ids`
    #   array.
    def find_parents(resource:)

    end

    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

      # @return [Array<Valkyrie::ID>] a list of the identifiers of the member objects
      def member_ids(resource:)
        return [] unless resource.respond_to? :member_ids
        resource.member_ids || []
      end

      def validate_id(id)
        raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
      end
  end
end
