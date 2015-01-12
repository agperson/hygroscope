- - -

> **hy·gro·scope**<br>
> _ˈhīɡrəˌskōp/_, noun<br>
> an instrument that gives an indication of the humidity of the air.

- - -

Hygroscope is a Thor-based command-line tool for managing the launch of complex CloudFormation stacks.

[CloudFormation](http://aws.amazon.com/cloudformation/) is a great way to manage infrastructure resources using code, but it has some aspects that make it a pain.
1. Templates must be written in JSON, which, in addition to being difficult for a human to read, does not support niceties such as inline comments and repeated blocks.
2. Launching CloudFormation stacks requires knowledge of the various parameters that need to be provided, and it is difficult to repeatably launch a stack since parameters are not saved in any convenient way.
3. There is no easy mechanism to send a payload of data to an instance during stack creation.
4. Finally, it is difficult to launch stacks that build upon already-existing stacks (i.e. an application stack within an existing VPC stack) because one must manually provide a variety of identifiers (subnets, IP addresses, security groups).

Hygroscope aims to solve each of these specific problems in an opinionated way:
1. CF templates are written in YAML and processed using [cfoo](https://github.com/drrb/cfoo), which provides a variety of convenience methods that increase readability.
2. Hygroscope can interactively prompt for each parameter and save inputted parameters to a state file. Additional stack launches can make use of existing state files.
3. A payload directory, if present, will be packaged and uploaded to S3. Hygroscope will generate and pass to CF an expiring URL for accessing and downloading the payload.
4. The outputs of stacks can be fetched and passed through as input parameters to dependent stacks.

Hygroscope is currently being developed and the exact commands and mechanisms for each process will be self-documented without the CLI.
