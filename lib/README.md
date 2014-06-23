
# Classes

## ServiceBackends

This class handles polling the consul API to build a list of services and the nodes that server them, and aggregating all server checks into per-service, per-node status.

### Testing

Tests are done with a mocked up consul service which provides static http results as expected from consul.

## ConsulConf

This class is mostly error handling.   It ties ServiceBackends together with Erubis to write out configs based on which servers are available.

### Responsibilities 

Given a config file and a Logger object, handle rendering the configured Erubis template into the configured destination.  

Use `diff` to check whether changes have been made, optionally using a configured regex to identify comment lines to ignore 

If specified, execute the postconfig ( eg calling HUP or restarting a service ).  Return result should be dependend of the postconfig action returning the expected exit status.

### Testing

Also uses a mocked up consul script, and a mocked up config, and writes out a mocked up template to test against.  

