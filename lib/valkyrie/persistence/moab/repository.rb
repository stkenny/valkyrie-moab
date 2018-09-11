# frozen_string_literal: true
require 'tempfile'

module Valkyrie::Persistence::Moab
  class Repository

    attr_reader :adapter, :resources

    def initialize(adapter:, resources:)
      @adapter = adapter
      @resources = resources
    end

    def persist
      resources.map do |resource|
        raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless valid_lock?(resource)

        internal_resource = resource.dup

        internal_resource = generate_id(internal_resource) if internal_resource.id.blank?
        internal_resource.created_at ||= Time.current
        internal_resource.updated_at = Time.current
        generate_lock_token(internal_resource)

        internal_resource = ResourceFactory.new.from_resource(resource: internal_resource)

        internal_resource.new_record = false
        internal_resource
      end
    end

    def delete
      resources.map do |resource|
        FileUtils.remove_dir(::Moab::StorageServices.object_path(resource.id.to_s), true)
      end
    end

    private

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
        resource.new(id: SecureRandom.uuid)
      end
  end
end
