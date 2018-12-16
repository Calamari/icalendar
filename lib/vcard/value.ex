defprotocol VCard.Value do
  @fallback_to_any true
  @spec to_ics(value :: term, params :: map) :: iodata
  def to_ics(value, params \\ %{})
end

alias VCard.Value
