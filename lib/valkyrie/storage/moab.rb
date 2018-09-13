require 'moab'

# frozen_string_literal: true
module Valkyrie::Storage
  class Moab
    include Valkyrie::Moab

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
      file_category = 'content'
      storage_object_id = resource.id.to_s
      add_to_moab(storage_object_id, file_category, file, original_filename)

      find_by(id: Valkyrie::ID.new("moab://#{storage_object_id}/#{file_category}/#{original_filename}"))
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

    # Return the file associated with the given identifier
    # @param id [Valkyrie::ID]
    # @return [Valkyrie::StorageAdapter::File]
    # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
    def find_by(id:)
      path = file_path(id)
      storage_object_id, file_category = id_from_path(path)

      moab_path = find_moab_filepath(storage_object_id, path, file_category)

      Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new(id.to_s), io: ::File.open(moab_path, 'rb'))
    rescue ::Moab::FileNotFoundException
      raise Valkyrie::StorageAdapter::FileNotFound
    end

    # Delete the file on disk associated with the given identifier.
    # @param id [Valkyrie::ID]
    def delete(id:)
      path = file_path(id)
      storage_object_id, file_category = id_from_path(path)

      delete_from_moab(storage_object_id, path, file_category)
    end
  end
end
