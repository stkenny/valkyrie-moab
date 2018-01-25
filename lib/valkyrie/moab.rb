# frozen_string_literal: true
require 'valkyrie'
require 'valkyrie/moab/version'
require 'valkyrie/persistence/moab'
require 'valkyrie/storage/moab'

module Valkyrie
  module Moab

    def add_to_moab(digital_object_id, group_id, file, original_filename)
      moab_action(digital_object_id) do |version, file_inventory|
        moab_path = File.join(version.version_pathname, 'data', group_id)
        FileUtils.mkpath(moab_path)

        version.ingest_file(file.path, File.join(moab_path, original_filename), false)

        add_file_to_inventory(Pathname.new(File.join(moab_path, original_filename)), file_inventory, group_id)
      end
    end

    def find_moab_filepath(path, digital_object_id, group_id)
      begin
        storage_object = storage_repository.storage_object(digital_object_id)
      rescue ::Moab::ObjectNotFoundException
        raise Valkyrie::StorageAdapter::FileNotFound
      end

      current_object_version = storage_object.current_version
      current_object_version.find_filepath(group_id, Pathname.new(path).basename)
    end

    def delete_from_moab(path, digital_object_id, group_id)
      moab_action(digital_object_id) do |_new_version, file_inventory|
        file_inventory.group(group_id).remove_file_having_path(Pathname.new(path).basename)
      end
    end

    private

      def add_file_to_inventory(path, file_inventory, group)
        file_signature = ::Moab::FileSignature.new
        file_signature.signature_from_file(path)

        file_instance = ::Moab::FileInstance.new
        file_instance.instance_from_file(path, path.parent)

        file_inventory.group(group).add_file_instance(file_signature, file_instance)
      end

      # Wrap the Moab action, either adding or deleting file
      # @param digital_object_id [String]
      def moab_action(digital_object_id)
        # get the current object version
        current_storage_object = storage_object_version(digital_object_id)
        signature_catalog = current_storage_object.signature_catalog

        # get the current version inventories and create new
        current_file_inventory = current_storage_object.file_inventory('version')

        new_file_inventory = current_storage_object.file_inventory('version')
        new_file_inventory.version_id = new_file_inventory.version_id + 1

        # create the storage area for the new version
        new_version = storage_object_version(digital_object_id, version: current_storage_object.version_id + 1)

        # perform the action
        yield(new_version, new_file_inventory)

        # write the updated manifests
        manifest_path = File.join(new_version.version_pathname, 'manifests')
        new_file_inventory.write_xml_file(Pathname.new(manifest_path))

        version_additions = signature_catalog.version_additions(new_file_inventory)
        version_additions.write_xml_file(Pathname.new(manifest_path))

        new_version.update_catalog(signature_catalog, new_file_inventory)
        new_version.generate_differences_report(current_file_inventory, new_file_inventory)

        new_version.generate_manifest_inventory
      end

      def storage_object_version(digital_object_id, version: nil)
        storage_object = storage_repository.storage_object(digital_object_id, create: true)

        return storage_object.current_version if version.nil?

        object_version = storage_object.storage_object_version(version)
        object_version.version_pathname.mkpath
        object_version
      end

      def storage_repository
        @storage_repository ||= ::Moab::StorageRepository.new
      end

  end
end
