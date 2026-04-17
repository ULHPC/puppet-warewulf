# frozen_string_literal: true

Facter.add(:warewulf) do
  confine kernel: :linux

  setcode do
    warewulf = {}
    wwctl = Facter::Core::Execution.execute('which wwctl')
    warewulf['images'] = Facter::Core::Execution.execute("#{wwctl} image ls").strip.lines[2..].map(&:strip)

    warewulf
  end
end
