stream = File.read!("test/fixtures/blank_description.ics")
{:ok, decoded} = ICalendar.Decoder.from_ics(stream)
ICalendar.Encoder.to_ics(decoded)
IO.inspect(decoded)

# :eflame.apply(ICalendar.Decoder, :decode, [stream])
#

Benchee.run(
  %{
    "decode" => fn -> ICalendar.Decoder.from_ics(stream) end,
    "encode" => fn -> ICalendar.Encoder.to_ics(decoded) end
  },
  time: 10,
  memory_time: 2
)
