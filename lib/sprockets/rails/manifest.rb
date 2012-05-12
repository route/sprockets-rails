require "fileutils"

module Sprockets
  module Rails
    class Manifest < ::Sprockets::Manifest
      def path=(path)
        @path = if File.extname(path) == ""
          File.join(path, 'manifest.json')
        else
          File.expand_path(path)
        end
        FileUtils.mkdir_p(File.dirname(@path))
      end

      def compile(*args)
        paths = environment.each_logical_path(*args).to_a +
          args.flatten.select { |fn| Pathname.new(fn).absolute? if fn.is_a?(String) }

        paths.each do |path|
          if asset = find_asset(path)
            files[asset.digest_path] = {
              'logical_path' => asset.logical_path,
              'mtime'        => asset.mtime.iso8601,
              'size'         => asset.bytesize,
              'digest'       => asset.digest
            }
            assets[asset.logical_path] = asset.digest_path

            target = target_for(asset)

            asset.write_to(target) unless File.exist?(target)

            save
            asset
          end
        end
      end

      def target_for(asset)
        if ::Rails.application.config.assets.digest
          File.join(dir, asset.digest_path)
        else
          File.join(dir, asset.logical_path)
        end
      end
    end
  end
end
