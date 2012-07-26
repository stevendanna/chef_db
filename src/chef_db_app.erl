%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Kevin Smith <kevin@opscode.com>
%% @author Christopher Maier <cm@opscode.com>
%% @author Seth Falcon <seth@opscode.com>
%% @copyright 2012 Opscode, Inc.
%% @end

-module(chef_db_app).

-behaviour(application).

-include_lib("eunit/include/eunit.hrl").
-include_lib("xmerl/include/xmerl.hrl").

%% Application callbacks
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    ok = load_ibrowse_config(),
    ok = enable_org_cache(),
    chef_common_sup:start_link().

stop(_State) ->
    ok.

load_ibrowse_config() ->
    ConfigFile = filename:absname(filename:join(["etc", "ibrowse", "ibrowse.config"])),
    error_logger:info_msg("Loading ibrowse configuration from ~s~n", [ConfigFile]),
    ok = ibrowse:rescan_config(ConfigFile),
    ok.

enable_org_cache() ->
    case application:get_env(chef_common, cache_defaults) of
        undefined ->
            error_logger:info_msg("Org guid cache disabled~n");
        {ok, _Defaults} ->
            chef_cache:init(org_guid),
            error_logger:info_msg("Org guid cache enabled~n")
    end,
    ok.