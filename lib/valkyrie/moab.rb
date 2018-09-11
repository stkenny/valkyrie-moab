# frozen_string_literal: true
require 'valkyrie'
require 'valkyrie/moab/version'
require 'valkyrie/persistence/moab'
require 'valkyrie/storage/moab'

module Valkyrie
  module Moab

    def add_to_moab(id, file_category, file, original_filename)
      moab_action(id) do |version, file_inventory|
        moab_path = File.join(version.version_pathname, 'data', file_category)
        FileUtils.mkpath(moab_path)

        version.ingest_file(file.path, File.join(moab_path, original_filename), false)

        add_file_to_inventory(Pathname.new(File.join(moab_path, original_filename)), file_inventory, file_category)
      end
    end

    def find_moab_filepath(id, path, file_category)
      storage_object = storage_repository.storage_object(id)

      current_object_version = storage_object.current_version
      current_object_version.find_filepath(file_category, Pathname.new(path).basename.to_s)
    rescue ::Moab::ObjectNotFoundException
      raise Valkyrie::StorageAdapter::FileNotFound
    end

    def delete_from_moab(id, path, file_category)
      moab_action(id) do |_new_version, file_inventory|
        file_inventory.group(file_category).remove_file_having_path(Pathname.new(path).basename.to_s)
      end
    end

    private

      def add_file_to_inventory(path, file_inventory, file_category)
        file_signature = ::Moab::FileSignature.new
        file_signature.signature_from_file(path)

        file_instance = ::Moab::FileInstance.new
        file_instance.instance_from_file(path, path.parent)

        file_inventory.group(file_category).add_file_instance(file_signature, file_instance)
      end

      # Wrap the Moab action, either adding or deleting file
      # @param id [String]
      def moab_action(id)
        # get the current object version
        current_storage_object = storage_object_version(id)
        signature_catalog = current_storage_object.signature_catalog

        # get the current version inventories and create new
        current_file_inventory = current_storage_object.file_inventory('version')
        new_file_inventory = updated_file_inventory(current_file_inventory, current_storage_object)

        # create the storage area for the new version
        new_version = storage_object_version(id, version: current_storage_object.version_id.next)

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

      def updated_file_inventory(current_file_inventory, storage_object)
        new_file_inventory = storage_object.file_inventory('version')
        new_file_inventory.version_id = new_file_inventory.version_id.next

        new_file_inventory
      end


      def storage_object_version(id, version: nil)
        storage_object = storage_repository.storage_object(id, create: true)

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
