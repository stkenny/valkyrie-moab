# frozen_string_literal: true
require 'tempfile'

module Valkyrie::Persistence::Moab
  class Repository
    include Valkyrie::Moab

    attr_reader :resources, :resource_factory

    delegate :adapter, to: :resource_factory

    def initialize(resources:, resource_factory:, storage_roots:, storage_trunk:)
      @resources = resources
      @resource_factory = resource_factory

      ::Moab::Config.storage_roots = storage_roots
      ::Moab::Config.storage_trunk = storage_trunk

      storage_roots.each { |root| FileUtils.mkpath(File.join(root, storage_trunk)) }
    end

    def persist    
      resources.map do |resource|
        raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless valid_lock?(resource)

        internal_resource = resource.dup

        internal_resource = generate_id(internal_resource) if internal_resource.id.blank?
        internal_resource.created_at ||= Time.current
        internal_resource.updated_at = Time.current
        generate_lock_token(internal_resource)
        
        metadata_file = Tempfile.new("#{internal_resource.id}_jsonld")
        begin
          File.open(metadata_file, "w") do |f|
            f.write(resource_metadata(internal_resource).to_json)
          end

          add_to_moab(internal_resource.id.to_s, 'metadata', metadata_file, "#{internal_resource.id}.jsonld")
        ensure
          metadata_file.close
          metadata_file.unlink   # deletes the temp file
        end

        internal_resource
      end
    end

    def delete
      
    end

    private

      def resource_metadata(resource)
        output = resource.to_h.except(:imported_metadata).compact
        if output[:optimistic_lock_token]
          output[:optimistic_lock_token] = Array.wrap(output[:optimistic_lock_token]).map(&:serialize)
        end
        output
      end

      def valid_lock?(resource)
        return true if resource.id.blank?
        return true unless resource.optimistic_locking_enabled?

        cached_resource = adapter.query_service.find_by(id: resource.id)
        return true if cached_resource.blank?

        resource_lock_tokens = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        resource_value = resource_lock_tokens.find { |lock_token| lock_token.adapter_id == adapter.id }
        return true if resource_value.blank?

        cached_value = cached_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first
        cached_value == resource_value
      end

      def generate_lock_token(resource)
        return unless resource.optimistic_locking_enabled?
        token = Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: adapter.id, token: Time.now.to_f)
        resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", token)
      end

      def generate_id(resource)
        Valkyrie.logger.warn "The Moab adapter is not meant to persist new resources, but is now generating an ID."
        resource.new(id: SecureRandom.uuid)
      end
  end
end