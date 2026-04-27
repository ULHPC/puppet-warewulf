# Warewulf

[![License](https://img.shields.io/github/license/ULHPC/puppet-warewulf.svg)](https://github.com/ULHPC/puppet-warewulf/blob/master/LICENSE)
![Build Status](https://github.com/ULHPC/puppet-warewulf/actions/workflows/ci.yml/badge.svg?branch=master)

#### Table of Contents

1. [Description](#description)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Limitations - OS compatibility, etc.](#limitations)

## Description

This puppet module manages [warewulf](https://warewulf.org/).
Warewulf is a stateless and diskless container operating system provisioning system for large clusters of bare metal and/or virtual systems.

## Usage

To start, include this module in your puppet code:

```puppet
node warewulf {
  include warewulf
}
```

The module is designed to be configured with hiera. But if needed you can configure it directly in your puppet code. For more details on how to configure this module take a look at the [reference](#reference).

## Reference

Reference documentation [REFERENCE.md](REFERENCE.md).

## Limitations

Details in [`metadata.json`](metadata.json).
