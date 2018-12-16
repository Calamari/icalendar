defprotocol ICalendar.Value do
  @fallback_to_any true
  @spec to_ics(value :: term, params :: map) :: iodata
  def to_ics(value, params \\ %{})
end

alias ICalendar.Value

# defimpl Value, for: Tuple do
#   def to_ics(vals, _opts) do
#     vals
#     |> Tuple.to_list()
#     |> Enum.map(&Value.to_ics/1)
#     # TODO configurable per field
#     |> Enum.join(";")
#   end
# end
defimpl Value, for: Tuple do
  defmacro elem2(x, i1, i2) do
    quote do
      unquote(x) |> elem(unquote(i1)) |> elem(unquote(i2))
    end
  end

  @doc """
  This macro is used to establish whether a tuple is in the Erlang Timestamp
  format (`{{year, month, day}, {hour, minute, second}}`).
  """
  defmacro is_datetime_tuple(x) do
    quote do
      # Year
      # Month
      # Day
      # Hour
      # Minute
      # Second
      unquote(x) |> elem2(0, 0) |> is_integer and unquote(x) |> elem2(0, 1) |> is_integer and
        unquote(x) |> elem2(0, 1) <= 12 and unquote(x) |> elem2(0, 1) >= 1 and
        unquote(x) |> elem2(0, 2) |> is_integer and unquote(x) |> elem2(0, 2) <= 31 and
        unquote(x) |> elem2(0, 2) >= 1 and unquote(x) |> elem2(1, 0) |> is_integer and
        unquote(x) |> elem2(1, 0) <= 23 and unquote(x) |> elem2(1, 0) >= 0 and
        unquote(x) |> elem2(1, 1) |> is_integer and unquote(x) |> elem2(1, 1) <= 59 and
        unquote(x) |> elem2(1, 1) >= 0 and unquote(x) |> elem2(1, 2) |> is_integer and
        unquote(x) |> elem2(1, 2) <= 60 and unquote(x) |> elem2(1, 2) >= 0
    end
  end

  @doc """
  This function converts Erlang timestamp tuples into DateTimes.
  """
  def to_ics(timestamp, _opts) when is_datetime_tuple(timestamp) do
    timestamp
    |> Timex.to_datetime()
    |> Value.to_ics()
  end

  def to_ics(x, _opts), do: x
end

defimpl Value, for: ICalendar.Binary do
  def to_ics(val, _opts) do
    Binary.to_ics64(val.val)
  end
end

defimpl Value, for: Atom do
  def to_ics(nil, _), do: ""
  def to_ics(true, _), do: "TRUE"
  def to_ics(false, _), do: "FALSE"

  def to_ics(atom, _options) do
    Atom.to_string(atom)
  end
end

defimpl Value, for: ICalendar.Address do
  def to_ics(val, opts) do
    val.val
  end
end

defimpl Value, for: Date do
  import ICalendar.Util, only: [zero_pad: 2]

  def to_ics(val, _) do
    zero_pad(val.year, 4) <> zero_pad(val.month, 2) <> zero_pad(val.day, 2)
  end
end

defimpl Value, for: DateTime do
  def to_ics(%{time_zone: "Etc/UTC"} = val, _options) do
    date = Value.to_ics(DateTime.to_date(val))
    time = Value.to_ics(DateTime.to_time(val))
    date <> "T" <> time <> "Z"
  end

  def to_ics(%{time_zone: time_zone} = val, _options) do
    date = Value.to_ics(DateTime.to_date(val))
    time = Value.to_ics(DateTime.to_time(val))

    {
      date <> "T" <> time,
      %{tzid: time_zone}
    }
  end
end

defimpl Value, for: NaiveDateTime do
  def to_ics(val, _options) do
    date = Value.to_ics(NaiveDateTime.to_date(val))
    time = Value.to_ics(NaiveDateTime.to_time(val))
    date <> "T" <> time
  end
end

defimpl Value, for: Timex.Duration do
  def to_ics(val, _options) do
    string = Timex.Format.Duration.Formatter.format(val)

    if val.seconds < 0 || val.megaseconds < 0 || val.microseconds < 0 do
      "-" <> string
    else
      string
    end
  end
end

defimpl Value, for: Float do
  def to_ics(val, _opts), do: to_string(val)
end

defimpl Value, for: Integer do
  def to_ics(val, _opts), do: to_string(val)
end

defimpl Value, for: ICalendar.Period do
  def to_ics(val, _opts) do
    from = Value.to_ics(val.from)
    until = Value.to_ics(val.until)
    from <> "/" <> until
  end
end

defimpl Value, for: ICalendar.RRULE do
  alias ICalendar.Util

  def to_ics(val, _opts) do
    val
    |> Map.from_struct()
    |> Map.keys()
    |> Util.RRULE.order_conventionally()
    |> Enum.map(&Util.RRULE.serialize(val, &1))
    |> Enum.reject(&(&1 == nil))
    |> Enum.join(";")
  end
end

defimpl Value, for: BitString do
  @escape ~r/\\|;|,|\n/
  def to_ics(val, _opts) do
    # TODO: optimize: only run the regex if string contains those chars
    Regex.replace(@escape, val, fn
      "\\" -> "\\\\"
      ";" -> "\\;"
      "," -> "\\,"
      "\n" -> "\\n"
      v -> v
    end)
  end
end

defimpl Value, for: ICalendar.Time do
  import ICalendar.Util, only: [zero_pad: 2]

  def to_ics(%{time_zone: "Etc/UTC"} = val, _opts) do
    zero_pad(val.hour, 2) <> zero_pad(val.minute, 2) <> zero_pad(val.second, 2) <> "Z"
  end

  def to_ics(%{time_zone: time_zone} = val, _opts) when not is_nil(time_zone) do
    {
      zero_pad(val.hour, 2) <> zero_pad(val.minute, 2) <> zero_pad(val.second, 2),
      %{tzid: time_zone}
    }
  end

  def to_ics(val, _opts) do
    zero_pad(val.hour, 2) <> zero_pad(val.minute, 2) <> zero_pad(val.second, 2)
  end
end

defimpl Value, for: Time do
  import ICalendar.Util, only: [zero_pad: 2]

  def to_ics(val, _opts) do
    zero_pad(val.hour, 2) <> zero_pad(val.minute, 2) <> zero_pad(val.second, 2)
  end
end

defimpl Value, for: URI do
  def to_ics(val, _opts) do
    URI.to_string(val)
  end
end

defimpl Value, for: ICalendar.UTCOffset do
  def to_ics(val, opts) do
    val.val
  end
end
