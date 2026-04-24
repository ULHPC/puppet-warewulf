# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the warewulf_image type using the Resource API.
# This provider interacts with Warewulf via the `wwctl` command-line tool.
# It supports fetching, creating, updating, and deleting Warewulf images.
#
class Puppet::Provider::WarewulfImage::WarewulfImage < Puppet::ResourceApi::SimpleProvider
  # The `get` method retrieves the current state of Warewulf images.
  # It is called by Puppet to determine the "is" state of resources.
  #
  # @param context [Puppet::ResourceApi::BaseContext] The context for logging and debugging.
  # @return [Array<Hash>] An array of hashes representing the current state of Warewulf images.
  #
  def get(context)
    context.debug('Fetching Warewulf images')

    wwctl('image', 'list').strip.lines[2..].map(&:strip).map do |image|
      {
        ensure: 'present',
        name: image,
      }
    end
  end

  # Add an image to Warewulf.
  #
  # @param context [Puppet::ResourceApi::BaseContext] The context for logging and debugging
  # @param name [String] The image name to add
  # @param should [Hash] additional parameters
  #
  def create(context, name, should)
    context.debug("Importing image '#{name}' with #{should.inspect}")

    cmd = [
      'image', 'import',
      "docker://#{should[:oci_repository_url]}/#{should[:oci_remote_name] || name}",
      name,
    ]

    cmd.append('--build') if should[:build]
    cmd.append('--syncuser') if should[:syncuser]
    cmd.append('--platform', should[:platform]) if should[:platform]

    wwctl(*cmd)
  end

  # Remove an image from Warewulf.
  #
  # @param context [Puppet::ResourceApi::BaseContext] The context for logging and debugging
  # @param name [String] The image name to remove
  #
  def delete(context, name)
    context.debug("Deleting image '#{name}'")
    wwctl('image', 'delete', name, '--yes')
  end

  # Get the path of wwctl.
  #
  # @return [String] The path of wwctl.
  #
  def wwctl_cmd
    @wwctl_cmd ||= Puppet::Util::Execution.execute('which wwctl 2> /dev/null').strip
  end

  # Executes the `wwctl` command with the specified arguments.
  # This method uses Puppet's `Puppet::Util::Execution.execute` to run the command.
  #
  # @param args [Array<String>] The arguments to pass to `wwctl`.
  # @return [String] The output of the command.
  #
  def wwctl(*args)
    Puppet::Util::Execution.execute([wwctl_cmd] + args)
  end
end
