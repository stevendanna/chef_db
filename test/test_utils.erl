% -*- mode: erlang; fill-column: 90; indent-tabs-mode: nil; set-trailing-whitespace: true -*-
%
% License:: Apache License, Version 2.0
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% @author Mark Anderson <mark@opscode.com>
% @copyright Copyright 2011 Opscode, Inc.
% @version 0.0.1
% @end

-module(test_utils).

-export([test_setup/0,
         test_cleanup/1,
         ensure_ibrowse/0,
         ensure_couch/0,
         start_stats_hero/0,
         mock/1,
         mock/2,
         unmock/1,
         validate_modules/1
        ]).

-define(superuser_name,  <<"platform-superuser">>).
-define(test_org_name, <<"clownco">>).
-define(test_org_admin, <<"clownco-org-admin">>).
-define(test_org_user1, <<"cooky">>).
-define(no_such_id, <<"deadbeefdeadbeefdeadbeefdeadbeef">>).
-define(authz_host, "http://localhost:5959").
-define(chef_host_name, "localhost").
-define(chef_host_port, 5984).

-include_lib("eunit/include/eunit.hrl").


test_setup() ->
    start_stats_hero(),
    Server = {context,<<"test-req-id">>,{server,"localhost",5984,[],[]}},
    Superuser = <<"cb4dcaabd91a87675a14ec4f4a00050d">>,
    {Server, Superuser}.

start_stats_hero() ->
    application:set_env(stats_hero, estatsd_host, "localhost"),
    application:set_env(stats_hero, estatsd_port, dumb_random_port()),
    application:set_env(stats_hero, udp_socket_pool_size, 5),
    application:start(stats_hero).

dumb_random_port() ->
    {ok, Socket} = gen_udp:open(0),
    {ok, Port} = inet:port(Socket),
    gen_udp:close(Socket),
    Port.

test_cleanup(_State) ->
    cleanup_ibrowse(),
    application:stop(ibrowse),
    case whereis(inet_gethost_native_sup) of
        P when is_pid(P) ->
            inet_gethost_native:terminate(shutdown, P);
        _ ->
            ok
    end,
    meck:unload(),
    ok.

ensure_ibrowse() ->
    case ibrowse:start() of
        {ok, _} -> ok;
        {error, {already_started, _}} -> ok;
        Error -> Error
    end.

cleanup_ibrowse() ->
    ibrowse:stop().

ensure_couch() ->
    application:set_env(chef_common, authz_root_url, ?authz_host),
    application:set_env(chef_common, couchdb_host, ?chef_host_name),
    application:set_env(chef_common, couchdb_port, ?chef_host_port),
    application:set_env(chef_common, dark_launch_sql_users, false),
    ensure_ibrowse().

%% helper functions for configuring mocking.

%%@doc setup mocking for a list of modules.  This would normally be
%% called in the setup/0 method. You can optionally pass in a list of
%% meck options. See meck docs for details at
%% http://doc.erlagner.org/meck/meck.html#new-2
mock(Modules) ->
  mock(Modules, []).
mock(Modules, Opts) ->
    [ meck:new(M, Opts) || M <- Modules ].

%%@doc Unload a list of mocked modules
unmock(Modules) ->
    [ meck:unload(M) || M <-Modules ].

%% @doc Validate the state of the mock modules and raise
%% an eunit error if the modules have not been used according to
%% expectations
validate_modules(Modules) ->
    [?assert(meck:validate(M)) || M <- Modules].
