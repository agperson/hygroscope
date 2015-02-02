- - -

> **hy·gro·scope**<br>
> _ˈhīɡrəˌskōp/_, noun<br>
> an instrument that gives an indication of the humidity of the air.

- - -

Hygroscope is a Thor-based command-line tool for managing the launch of complex CloudFormation stacks.

[CloudFormation](http://aws.amazon.com/cloudformation/) is a great way to manage infrastructure resources using code, but it has some aspects that make it a pain:

1. Templates must be written in JSON, which, in addition to being difficult for a human to read, does not support niceties such as inline comments and repeated blocks.
2. Launching CloudFormation stacks requires knowledge of the various parameters that need to be provided, and it is difficult to repeatably launch a stack since parameters are not saved in any convenient way.
3. There is no easy mechanism to send a payload of data to an instance during stack creation (for instance scripts and recipes to bootstrap an instance).
4. Finally, it is difficult to launch stacks that build upon already-existing stacks (i.e. an application stack within an existing VPC stack) because one must manually provide a variety of identifiers (subnets, IP addresses, security groups).

Hygroscope aims to solve each of these specific problems in an opinionated way:

1. CF templates are written in YAML and processed using [cfoo](https://github.com/drrb/cfoo), which provides a variety of convenience methods that increase readability.
2. Hygroscope can interactively prompt for each parameter and save inputted parameters to a file called a paramset. Additional stack launches can make use of existing paramsets, or can use paramsets as the basis and prompt for updated parameters.
3. A payload directory, if present, will be packaged and uploaded to S3. Hygroscope will generate and pass to CF a signed time-limited URL for accessing and downloading the payload, or the CloudFormation template can manage an instance profile granting indefinite access to the payload.
4. If an existing stack is specified, its outputs will be fetched and passed through as input parameters when launching a new stack.

Hygroscope is currently under development but mostly functional. Run `hygroscope help` to view inline command documentation and options.  See [template structure](wiki/Structure-of-a-Hygroscopic-Template) for information about the format of hygroscopic templates.
