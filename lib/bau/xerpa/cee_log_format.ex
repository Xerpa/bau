defmodule Bau.Xerpa.CeeLogFormat do
  @doc """
  formats an structured log using sd-daemon(3) log and rsyslog cee
  format [1]. the log message has the following structure:

  ```
  {
    "msg": STRING
    "meta": OBJECT
    "xerpa": OBJECT
  }
  ```

  Note, that `OBJECT` values are restricted to `binary`, `integer`,
  `float`, `atom` and `boolean`. Any other type are converted to
  `binary` using `inspect`.

  [1] https://www.rsyslog.com/doc/v8-stable/configuration/modules/mmjsonparse.html
  """
  def format(level, message, _timestamp, metadata) do
    xerpadata =
      Map.new(
        Process.get({__MODULE__, :metadata}, Application.get_env(:logger, :xerpa_metadata, []))
      )

    jsonlog =
      %{msg: IO.iodata_to_binary(message)}
      |> Map.put(:meta, Map.new(metadata, &sanitize/1))
      |> Map.put(:xerpa, Map.new(xerpadata, &sanitize/1))
      |> Poison.encode!()

    level =
      case level do
        :debug -> "<7>"
        :info -> "<6>"
        :warn -> "<4>"
        :error -> "<3>"
      end

    "#{level}@cee: #{jsonlog}\n"
  rescue
    _ ->
      "<2>ERROR FORMATTING MESSAGE: #{
        inspect({message, metadata}, pretty: false, safe: true, limit: :infinity)
      }"
  end

  defp sanitize({k, v}) do
    if is_binary(v) or is_integer(v) or is_float(v) or is_atom(v) or is_boolean(v) do
      {k, v}
    else
      {k, inspect(v, pretty: false, safe: true, limit: :infinity)}
    end
  end
end
