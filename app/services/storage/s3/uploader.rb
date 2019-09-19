require 'aws-sdk-s3'
require 'pathname'

module Storage
  module S3
    class Uploader
      def initialize(path:, key:, bucket:)
        @path = Pathname.new(path)
        @key = key
        @bucket = bucket
      end

      def upload
        encrypt
        object.upload_file(path_to_encrypted_file)
        File.delete(path_to_encrypted_file)
      end

      def exists?
        object.exists?
      end

      def purge_from_s3!
        object.delete
      end

      def created_at
        object.last_modified
      end

      private

      attr_accessor :path, :key, :bucket

      def encrypt
        file = File.open(path, 'rb')
        data = file.read
        file.close
        result = Cryptography.new(file: data).encrypt
        save_encrypted_to_disk(result)
      end

      def save_encrypted_to_disk(data)
        ensure_encrypted_folder_exists
        encrypted_file = File.open(path_to_encrypted_file, 'wb')
        encrypted_file.write(data)
        encrypted_file.close
      end

      def path_to_encrypted_file
        @path_to_encrypted_file ||= Rails.root.join('tmp/files/encrypted_data/', random_filename)
      end

      def ensure_encrypted_folder_exists
        FileUtils.mkdir_p(encrypted_folder)
      end

      def encrypted_folder
        Rails.root.join('tmp/files/encrypted_data/')
      end

      def object
        @object ||= Aws::S3::Object.new(bucket, key, client: client)
      end

      def client
        @client ||= Aws::S3::Client.new
      end

      def random_filename
        @random_filename ||= SecureRandom.hex
      end
    end
  end
end
