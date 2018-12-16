defmodule ICalendar.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :icalendar,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "iCalendar",
      source_url: "https://github.com/calamari/icalendar",
      description: "Parse and manipulate iCalendar (RFC5545)",
      package: [
        maintainers: ["Georg Tavonius"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/calamari/icalendar"}
      ]
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      # Code style linter
      {:dogma, ">= 0.0.0", only: ~w(dev test)a},
      # Automatic test runner
      {:mix_test_watch, ">= 0.0.0", only: :dev},

      # Markdown processor
      {:earmark, "~> 1.0", only: [:dev, :test]},
      # Documentation generator
      {:ex_doc, "~> 0.18", only: [:dev, :test]},

      # Benchmarks
      {:benchee, "~> 0.11", only: :dev},
      {:benchee_html, "~> 0.4", only: :dev},

      # Timezones, period parsing, intervals
      {:timex, "~> 3.0"},
      {:calendar, "~> 0.17.2"},
      {:eflame, "~> 1.0.1", only: :dev}
    ]
  end
end
