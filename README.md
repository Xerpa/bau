# Bau

Xerpa goodies:

* Custom Log Formatter
* Exception Handler for Absinthe
* Conduit Dead Letter Plug
* Conduit JSON Plug
* Conduit Request ID Plug
* Conduit Retry Plug
* Enum by Xerpa
* Slack Notifier
* Tesla Request ID Forwarder Middleware

# How install
In order to install in your project, add to you `mix.ex` `deps`
function:

```elixir
	[
		{:bau, github: "xerpa/bau", ref: "current_stable_ref"}
	]
```

And run: 
```sh
	$ mix deps.install
```
