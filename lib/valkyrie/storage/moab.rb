require 'moab'

# frozen_string_literal: true
module Valkyrie::Storage
  class Moab
    attr_reader :storage_roots, :storage_trunk
    def initialize(storage_roots:, storage_trunk:)
      ::Moab::Config.storage_roots = storage_roots
      ::Moab::Config.storage_trunk = storage_trunk

      storage_roots.each { |root| FileUtils.mkpath(File.join(root, storage_trunk)) }
    end

    # @param file [IO]
    # @param original_filename [String]
    # @param resource [Valkyrie::Resource]
    # @return [Valkyrie::StorageAdapter::File]
    def upload(file:, original_filename:, resource:)
      digital_object_id = resource.id.to_s

      moab_action(digital_object_id) do |version, file_inventory|
        content_path = File.join(version.version_pathname, 'data', 'content')
        FileUtils.mkpath(content_path)

        version.ingest_file(file.path, File.join(content_path, original_filename))

        add_file_to_inventory(Pathname.new(File.join(content_path, original_filename)), file_inventory)
      end

      find_by(id: Valkyrie::ID.new("moab://#{digital_object_id}/content/#{original_filename}"))
    end

    def add_file_to_inventory(path, file_inventory)
      file_signature = ::Moab::FileSignature.new
      file_signature.signature_from_file(path)

      file_instance = ::Moab::FileInstance.new
      file_instance.instance_from_file(path, path.parent)

      file_inventory.group('content').add_file_instance(file_signature, file_instance)
    end

    # @param id [Valkyrie::ID]
    # @return [Boolean] true if this adapter can handle this type of identifer
    def handles?(id:)
      id.to_s.start_with?("moab://")
    end

    def file_path(id)
      id.to_s.gsub(/^moab:\/\//, '')
    end

    def id_from_path(path)
      Pathname.new(path).dirname.split.map(&:to_s)
    end

    def storage_repository
      @storage_repository ||= ::Moab::StorageRepository.new
    end

    # Return the file associated with the given identifier
    # @param id [Valkyrie::ID]
    # @return [Valkyrie::StorageAdapter::File]
    # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
    def find_by(id:)
      path = file_path(id)
      digital_object_id, group_id = id_from_path(path)

      begin
        storage_object = storage_repository.storage_object(digital_object_id)
      rescue ::Moab::ObjectNotFoundException
        raise Valkyrie::StorageAdapter::FileNotFound
      end

      current_object_version = storage_object.current_version
      moab_path = current_object_version.find_filepath(group_id, Pathname.new(path).basename)

      Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new(id.to_s), io: ::File.open(moab_path, 'rb'))
    rescue ::Moab::FileNotFoundException
      raise Valkyrie::StorageAdapter::FileNotFound
    end

    # Delete the file on disk associated with the given identifier.
    # @param id [Valkyrie::ID]
    def delete(id:)
      path = file_path(id)
      digital_object_id, group_id = id_from_path(path)

      moab_action(digital_object_id) do |_new_version, file_inventory|
        file_inventory.group(group_id).remove_file_having_path(Pathname.new(path).basename)
      end
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
  end
end
