require "fileutils"

module Sprockets
  module Rails
    class Manifest < ::Sprockets::Manifest
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

            if File.exist?(target)
              logger.debug "Skipping #{target}, already exists"
            else
              logger.info "Writing #{target}"
              asset.write_to target
            end

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
