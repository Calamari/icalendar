defmodule ICalendar.ParserTest do
  use ExUnit.Case
  alias ICalendar.Decoder
  # alias ICalendar.Event
  doctest ICalendar.Decoder
  doctest ICalendar.Period

  test "decode basic event" do
    stream = File.read!("test/fixtures/event.ics")
    {:ok, res} = Decoder.from_ics(stream)

    {:ok, dtstart} = Calendar.DateTime.from_erl({{2005, 01, 20}, {17, 0, 0}}, "US/Mountain")
    {:ok, dtend} = Calendar.DateTime.from_erl({{2005, 01, 20}, {18, 45, 0}}, "US/Mountain")
    {:ok, dtstamp} = Calendar.DateTime.from_erl({{2005, 01, 18}, {21, 15, 23}}, "Etc/UTC")
    {:ok, rdate1} = Calendar.DateTime.from_erl({{2005, 01, 21}, {17, 0, 0}}, "US/Mountain")
    {:ok, rdate2} = Calendar.DateTime.from_erl({{2005, 01, 22}, {17, 0, 0}}, "US/Mountain")

    assert res == %{
             __type__: :event,
             attach: [
               {%URI{
                  authority: "corporations-dominate.existence.net",
                  fragment: nil,
                  host: "corporations-dominate.existence.net",
                  path: "/why.rhtml",
                  port: 80,
                  query: nil,
                  scheme: "http",
                  userinfo: nil
                }, %{}},
               {%URI{
                  authority: "bush.sucks.org",
                  fragment: nil,
                  host: "bush.sucks.org",
                  path: "/impeach/him.rhtml",
                  port: 80,
                  query: nil,
                  scheme: "http",
                  userinfo: nil
                }, %{}}
             ],
             class: {"PRIVATE", %{}},
             dtend: {dtend, %{tzid: "US/Mountain"}},
             dtstamp: {dtstamp, %{}},
             dtstart: {dtstart, %{tzid: "US/Mountain"}},
             geo: {{37.386013, -122.0829322}, %{}},
             organizer: {%ICalendar.Address{val: "mailto:joebob@random.net"}, %{}},
             priority: {2, %{}},
             rdate:
               {[
                  rdate1,
                  rdate2
                ], %{tzid: "US/Mountain"}},
             summary:
               {"This is a really long summary to test the method of unfolding lines, so I'm just going to make it a whole bunch of lines.",
                %{}},
             uid: {"bsuidfortestabc123", %{}},
             x_test_component: {"Shouldn't double double quotes", %{qtest: "Hello, World"}}
           }
  end

  test "can parse gmail description" do
    stream = File.read!("test/fixtures/gmail_description.ics")
    {:ok, res} = Decoder.from_ics(stream)

    res.event |> IO.inspect()

    assert String.contains?(
             elem(res.event.description, 0),
             "Please do not edit this section of the description."
           )
  end

  test "nested" do
    stream = File.read!("test/fixtures/vcalendar.ics")
    {:ok, res} = Decoder.from_ics(stream)

    {:ok, dtstart} = Calendar.DateTime.from_erl({{2017, 04, 19}, {9, 15, 0}}, "Etc/UTC")
    {:ok, dtend} = Calendar.DateTime.from_erl({{2017, 04, 19}, {10, 25, 0}}, "Etc/UTC")
    {:ok, dtstamp} = Calendar.DateTime.from_erl({{2017, 04, 18}, {09, 13, 29}}, "Etc/UTC")
    {:ok, alarm_trigger} = Calendar.DateTime.from_erl({{2017, 04, 18}, {11, 05, 0}}, "Etc/UTC")

    assert res == %{
             __type__: :calendar,
             calscale: {"GREGORIAN", %{}},
             event: %{
               __type__: :event,
               alarm: %{
                 __type__: :alarm,
                 action: {"DISPLAY", %{}},
                 description: {"testing reminders n stuff", %{}},
                 trigger: {alarm_trigger, %{}}
               },
               attendee: [
                 {%ICalendar.Address{val: "mailto:mike@example.org"},
                  %{
                    cn: "Mike Douglass",
                    cutype: "INDIVIDUAL",
                    partstat: "NEEDS-ACTION",
                    rsvp: "TRUE"
                  }},
                 {%ICalendar.Address{val: "mailto:bernard@example.net"},
                  %{
                    cn: "Bernard Desruisseaux",
                    cutype: "INDIVIDUAL",
                    partstat: "NEEDS-ACTION",
                    role: "REQ-PARTICIPANT",
                    rsvp: "TRUE"
                  }},
                 {%ICalendar.Address{val: "mailto:wilfredo@example.com"},
                  %{
                    cn: "Wilfredo Sanchez Vega",
                    cutype: "INDIVIDUAL",
                    partstat: "NEEDS-ACTION",
                    role: "REQ-PARTICIPANT",
                    rsvp: "TRUE"
                  }},
                 {%ICalendar.Address{val: "mailto:cyrus@example.com"},
                  %{cn: "Cyrus Daboo", cutype: "INDIVIDUAL", partstat: "ACCEPTED"}}
               ],
               description: {"some HTML in here", %{}},
               dtend: {dtend, %{}},
               dtstamp: {dtstamp, %{}},
               dtstart: {dtstart, %{}},
               location: {"here", %{}},
               organizer:
                 {%ICalendar.Address{val: "mailto:cyrus@example.com"}, %{cn: "Cyrus Daboo"}},
               sequence: {3, %{}},
               status: {"CONFIRMED", %{}},
               summary: {"test reminder2", %{}},
               transp: {"OPAQUE", %{}},
               uid: {"00U5E000001JfN7UAK", %{}}
             },
             method: {"REQUEST", %{}},
             prodid: {"-//Google Inc//Google Calendar 70.9054//EN", %{}},
             version: {"2.0", %{}}
           }
  end

  test "duration" do
    stream = File.read!("test/fixtures/vcalendar_with_duration.ics")
    {:ok, res} = Decoder.from_ics(stream)

    duration = Timex.Duration.from_clock({3, 12, 25, 1000})
    {:ok, dtstart} = Calendar.DateTime.from_erl({{2017, 04, 19}, {9, 15, 0}}, "Etc/UTC")
    {:ok, dtend} = Calendar.DateTime.from_erl({{2017, 04, 19}, {10, 25, 0}}, "Etc/UTC")

    assert res == %{
             __type__: :calendar,
             calscale: {"GREGORIAN", %{}},
             event: %{
               __type__: :event,
               alarm: %{
                 __type__: :alarm,
                 action: {"DISPLAY", %{}},
                 description: {"testing reminders n stuff", %{}},
                 trigger: {duration, %{}}
               },
               description: {"some HTML in here", %{}},
               dtend: {dtend, %{}},
               dtstart: {dtstart, %{}},
               location: {"here", %{}},
               sequence: {3, %{}},
               status: {"CONFIRMED", %{}},
               summary: {"test reminder2", %{}},
               transp: {"OPAQUE", %{}},
               uid: {"00U5E000001JfN7UAK", %{}}
             },
             method: {"REQUEST", %{}},
             prodid: {"-//Google Inc//Google Calendar 70.9054//EN", %{}},
             version: {"2.0", %{}}
           }
  end

  test "period" do
    stream = File.read!("test/fixtures/event_with_period.ics")
    {:ok, res} = Decoder.from_ics(stream)

    {:ok, dtstart} = Calendar.DateTime.from_erl({{2017, 04, 19}, {9, 15, 0}}, "Etc/UTC")
    {:ok, dtend} = Calendar.DateTime.from_erl({{2017, 04, 19}, {10, 25, 0}}, "Etc/UTC")

    {:ok, p1start} = Calendar.DateTime.from_erl({{1996, 04, 03}, {2, 0, 0}}, "Etc/UTC")
    {:ok, p1end} = Calendar.DateTime.from_erl({{1996, 04, 03}, {4, 0, 0}}, "Etc/UTC")
    {:ok, p2start} = Calendar.DateTime.from_erl({{1996, 04, 04}, {1, 0, 0}}, "Etc/UTC")
    p2duration = Timex.Duration.from_clock({3, 0, 0, 0})

    assert res == %{
             __type__: :event,
             description: {"some HTML in here", %{}},
             dtend: {dtend, %{}},
             dtstart: {dtstart, %{}},
             location: {"here", %{}},
             rdate:
               {[
                  %ICalendar.Period{
                    from: p1start,
                    until: p1end
                  },
                  %ICalendar.Period{
                    from: p2start,
                    until: p2duration
                  }
                ], %{}},
             status: {"CONFIRMED", %{}},
             summary: {"test reminder2", %{}},
             uid: {"00U5E000001JfN7UAK", %{}}
           }
  end

  # TODO: this test is broken
  # test "failing negative duration" do
  #   attr = "-PT10M"
  #   res = Decoder.parse_type(attr, :duration, %{}) |> IO.inspect()
  # end

  test "decode tricky line with dquote" do
    str =
      ~s(BEGIN:VEVENT\nDESCRIPTION;ALTREP="cid:part1.0001@example.org":The Fall'98 Wild Wizards Conference - Las Vegas\, NV\, USA\nEND:VEVENT)

    {:ok, res} = Decoder.from_ics(str)

    assert res ==
             %{
               __type__: :event,
               description:
                 {"The Fall'98 Wild Wizards Conference - Las Vegas, NV, USA",
                  %{altrep: "cid:part1.0001@example.org"}}
             }
  end

  # @TODO: fix this
  test "RRULE parsing" do
    str = ~s"""
    BEGIN:VCALENDAR
    BEGIN:VTIMEZONE
    LAST-MODIFIED:20040110T032845Z
    TZID:US/Eastern
    BEGIN:DAYLIGHT
    DTSTART:20000404T020000
    RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4
    TZNAME:EDT
    TZOFFSETFROM:-0500
    TZOFFSETTO:-0400
    END:DAYLIGHT
    END:VTIMEZONE
    END:VCALENDAR
    """

    {:ok, res} = Decoder.from_ics(str)
    {:ok, last_modified} = Calendar.DateTime.from_erl({{2004, 01, 10}, {3, 28, 45}}, "Etc/UTC")

    assert res == %{
             __type__: :calendar,
             timezone: %{
               __type__: :timezone,
               daylight: %{
                 __type__: :daylight,
                 dtstart: {~N[2000-04-04 02:00:00], %{}},
                 rrule:
                   {%ICalendar.RRULE{
                      by_day: [{1, :sunday}],
                      by_hour: [],
                      by_minute: [],
                      by_month: [:april],
                      by_month_day: [],
                      by_second: [],
                      by_set_pos: [],
                      by_week_number: [],
                      by_year_day: [],
                      count: nil,
                      errors: [],
                      frequency: :yearly,
                      interval: nil,
                      until: nil,
                      week_start: nil,
                      x_name: nil
                    }, %{}},
                 tzname: {"EDT", %{}},
                 tzoffsetfrom: {%ICalendar.UTCOffset{val: "-0500"}, %{}},
                 tzoffsetto: {%ICalendar.UTCOffset{val: "-0400"}, %{}}
               },
               last_modified: {last_modified, %{}},
               tzid: {"US/Eastern", %{}}
             }
           }
  end

  # TODO Should this really fail? Because it doesn't
  # test "failing duration 1PDT" do
  #   str = ~s"""
  #   BEGIN:VCALENDAR
  #   VERSION:2.0
  #   PRODID:-//PYVOBJECT//NONSGML Version 1//EN
  #   BEGIN:VEVENT
  #   UID:put-6@example.com
  #   DTSTART;VALUE=DATE:20190427
  #   DURATION:P1DT
  #   DTSTAMP:20051222T205953Z
  #   X-TEST;CN=George Herman ^'Babe^' Ruth:test
  #   X-TEXT;P=Hello^World:test
  #   SUMMARY:event 6
  #   END:VEVENT
  #   END:VCALENDAR
  #   """
  #
  #   {:ok, res} = Decoder.from_ics(str)
  #   IO.inspect(res)
  # end
end
