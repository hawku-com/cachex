defmodule Cachex.ServicesTest do
  use CachexCase

  test "generating application service definitions" do
    assert [
             %{id: Services.Overseer, start: {Services.Overseer, _, _}},
             %{id: Services.Locksmith, start: {Services.Locksmith, _, _}}
           ] = Services.app_spec()
  end

  test "generating default cache specifications" do
    # generate the test cache state
    name = Helper.create_cache()
    cache = Services.Overseer.retrieve(name)

    # validate the services
    assert [
             %{id: Eternal, start: {Eternal, _, _}},
             %{
               id: Services.Locksmith.Queue,
               start: {Services.Locksmith.Queue, _, _}
             },
             %{id: Services.Informant, start: {Services.Informant, _, _}},
             %{id: Services.Incubator, start: {Services.Incubator, _, _}},
             %{id: Services.Courier, start: {Services.Courier, _, _}},
             %{id: Services.Janitor, start: {Services.Janitor, _, _}}
           ] = Services.cache_spec(cache)
  end

  test "generating cache limit specifications" do
    # generate the test cache state with a limit attached
    name =
      Helper.create_cache(limit: limit(size: 10, policy: __MODULE__.TestPolicy))

    cache = Services.Overseer.retrieve(name)

    # validate the services
    assert [
             %{id: Eternal, start: {Eternal, _, _}},
             %{
               id: Services.Locksmith.Queue,
               start: {Services.Locksmith.Queue, _, _}
             },
             %{id: Services.Informant, start: {Services.Informant, _, _}},
             %{id: Services.Incubator, start: {Services.Incubator, _, _}},
             %{id: Services.Courier, start: {Services.Courier, _, _}},
             %{id: Services.Janitor, start: {Services.Janitor, _, _}},
             %{
               id: Supervisor,
               start: {Supervisor, _, [[%{id: __MODULE__.TestPolicy}], _]}
             }
           ] = Services.cache_spec(cache)
  end

  test "skipping cache janitor specifications" do
    # generate the test cache state with the Janitor disabled
    name = Helper.create_cache(expiration: expiration(interval: nil))
    cache = Services.Overseer.retrieve(name)

    # validate the services
    assert [
             %{id: Eternal, start: {Eternal, _, _}},
             %{
               id: Services.Locksmith.Queue,
               start: {Services.Locksmith.Queue, _, _}
             },
             %{id: Services.Informant, start: {Services.Informant, _, _}},
             %{id: Services.Incubator, start: {Services.Incubator, _, _}},
             %{id: Services.Courier, start: {Services.Courier, _, _}}
           ] = Services.cache_spec(cache)
  end

  test "locating running services" do
    # generate the test cache state with the Janitor disabled
    name = Helper.create_cache(expiration: expiration(interval: nil))
    cache = Services.Overseer.retrieve(name)

    # validate the service locations
    assert Services.locate(cache, Services.Courier) != nil
    assert Services.locate(cache, Services.Janitor) == nil
  end

  defmodule TestPolicy do
    use Cachex.Policy

    def child_spec(_limit),
      do: [%{id: __MODULE__, start: {__MODULE__, :start_link, []}}]

    def start_link,
      do: :ignore
  end
end
