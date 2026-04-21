# frozen_string_literal: true

Facter.add(:warewulf) do
  confine kernel: :linux

  @wwctl_cmd = Facter::Util::Resolution.which('wwctl')
  confine { @wwctl_cmd }

  setcode do
    warewulf = {}
    warewulf['images'] = Facter::Core::Execution.execute("#{@wwctl_cmd} image ls").strip.lines[2..].map(&:strip)

    warewulf
  end
end
