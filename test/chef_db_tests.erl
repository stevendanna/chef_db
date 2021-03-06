%% Copyright 2012 Opscode, Inc. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%

-module(chef_db_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("emysql/include/emysql.hrl").
-include_lib("chef_objects/include/chef_types.hrl").

fetch_requestor_test_() ->
    {foreach,
     fun() ->
             meck:new(chef_sql),
             meck:new(chef_db_darklaunch),
             meck:new(chef_otto),
             set_app_env()
     end,
     fun(_) ->
             meck:unload()
     end,
     [
      {"a user is found SQL",
       fun() ->
               meck:expect(chef_otto, connect, fun() -> otto_connect end),
               meck:expect(chef_db_darklaunch, is_enabled, fun(<<"sql_users">>) -> true end),
               meck:expect(chef_db_darklaunch, is_enabled, fun(<<"couchdb_clients">>) -> false end),
               User = #chef_user{id = <<"a1">>,
                                 authz_id = <<"b2">>,
                                 username = <<"alice">>,
                                 pubkey_version = 1,
                                 public_key = <<"key data">>},
               meck:expect(chef_sql, fetch_user,
                           fun(<<"alice">>) -> {ok, User } end),
               Context = chef_db:make_context(<<"req-id-123">>),
               Got = chef_db:fetch_requestor(Context, <<"mock-org">>, <<"alice">>),
               ?assertEqual(Got, User)
       end
      },
      {"a client is found SQL cert",
       fun() ->
               meck:expect(chef_otto, connect, fun() -> otto_connect end),
               meck:expect(chef_otto, fetch_org_id,
                           fun(_, <<"mock-org">>) ->
                                   <<"mock-org-id-123">>
                           end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"sql_users">>) -> true end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"couchdb_clients">>) -> false end),
               meck:expect(chef_sql, fetch_user,
                           fun(<<"alice">>) -> {ok, not_found} end),
               Client = #chef_client{id = <<"mock-client-id">>,
                                     authz_id = <<"mock-client-authz-id">>,
                                     org_id = <<"org-id-123">>,
                                     name = <<"alice">>,
                                     pubkey_version = 1,
                                     public_key = <<"key data">>},
               meck:expect(chef_sql, fetch_client,
                           fun(<<"mock-org-id-123">>, <<"alice">>) -> {ok, Client} end),
               Context = chef_db:make_context(<<"req-id-123">>),
               Got = chef_db:fetch_requestor(Context, <<"mock-org">>, <<"alice">>),
               ?assertEqual(Got, Client)
       end
      },
      {"a client is found SQL key",
       fun() ->
               meck:expect(chef_otto, connect, fun() -> otto_connect end),
               meck:expect(chef_otto, fetch_org_id,
                           fun(_, <<"mock-org">>) ->
                                   <<"mock-org-id-123">>
                           end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"sql_users">>) -> true end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"couchdb_clients">>) -> false end),
               meck:expect(chef_sql, fetch_user,
                           fun(<<"alice">>) -> {ok, not_found} end),
            Client = #chef_client{id = <<"mock-client-id">>,
                                  authz_id = <<"mock-client-authz-id">>,
                                  org_id = <<"org-id-123">>,
                                  name = <<"alice">>,
                                  pubkey_version = 0,
                                  public_key = <<"key data">>},
               meck:expect(chef_sql, fetch_client,
                           fun(<<"mock-org-id-123">>, <<"alice">>) -> {ok, Client} end),
               Context = chef_db:make_context(<<"req-id-123">>),
               Got = chef_db:fetch_requestor(Context, <<"mock-org">>, <<"alice">>),
               ?assertEqual(Got, Client)
       end
      },
      {"a client is found Couchdb",
       fun() ->
               meck:expect(chef_otto, connect, fun() -> otto_connect end),
               meck:expect(chef_otto, fetch_org_id,
                           fun(_, <<"mock-org">>) ->
                                   <<"mock-org-id-123">>
                           end),
               meck:expect(chef_sql, fetch_user,
                           fun(<<"alice">>) -> {ok, not_found} end),
               Client = #chef_client{id = <<"mock-client-id">>,
                                     authz_id = <<"mock-client-authz-id">>,
                                     org_id = <<"org-id-123">>,
                                     name = <<"alice">>,
                                     pubkey_version = 1,
                                     public_key = <<"key data">>},
               meck:expect(chef_otto, fetch_client,
                           fun(_, <<"mock-org-id-123">>, <<"alice">>) -> Client end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"sql_users">>) -> true end),
               meck:expect(chef_db_darklaunch, is_enabled,
                           fun(<<"couchdb_clients">>) -> true end),
               Context = chef_db:make_context(<<"req-id-123">>),
               Got = chef_db:fetch_requestor(Context, <<"mock-org">>, <<"alice">>),
               ?assertEqual(Got, Client)
       end
      }
     ]}.

fetch_cookbook_versions_test_() ->
    {foreach,
     fun() ->
             meck:new(chef_sql),
             meck:new(chef_otto),
             meck:expect(chef_otto, connect, fun() -> otto_connect end),
             meck:expect(chef_otto, fetch_org_id,
                         fun(_, <<"mock-org">>) ->
                                <<"mock-org-id-123">>
                         end),
             set_app_env()
     end,
     fun(_) ->
             ?assert(meck:validate(chef_sql)),
             ?assert(meck:validate(chef_otto)),
             meck:unload()
     end,
     [
       {"fetch_cookbook_versions returns list containing empty list on no results",
         fun() ->
             SqlOutput = [[ ]],
             meck:expect(chef_sql, fetch_cookbook_versions,
                         fun(_) -> {ok, SqlOutput} end),
             Ctx = chef_db:make_context(<<"req-id-123">>),
             ?assertEqual(SqlOutput, chef_db:fetch_cookbook_versions(Ctx, <<"mock-org">>))
         end},
       {"fetch_cookbook_versions passes structured list",
         fun() ->
             SqlOutput = [[ <<"foo">>, {1, 2, 3} ]],
             meck:expect(chef_sql, fetch_cookbook_versions,
                         fun(_) -> {ok, SqlOutput} end),
             Ctx = chef_db:make_context(<<"req-id-123">>),
             ?assertEqual(SqlOutput, chef_db:fetch_cookbook_versions(Ctx, <<"mock-org">>))
         end},
       {"fetch_cookbook_versions handles errors",
         fun() ->
             meck:expect(chef_sql, fetch_cookbook_versions,
                         fun(_) -> {error, internal_error} end),
             Ctx = chef_db:make_context(<<"req-id-123">>),
             ?assertEqual({error, internal_error}, chef_db:fetch_cookbook_versions(Ctx, <<"mock-org">>))
         end},
       {"fetch_cookbook_versions handles errors",
         fun() ->
             meck:expect(chef_sql, fetch_cookbook_versions,
                         fun(_) -> {error, internal_error} end),
             Ctx = chef_db:make_context(<<"req-id-123">>),
             ?assertEqual({error, internal_error}, chef_db:fetch_cookbook_versions(Ctx, <<"mock-org">>))
         end}
     ]
    }.

create_fun_test_() ->
    [
     ?_assertEqual(create_data_bag_item, chef_db:create_fun(#chef_data_bag_item{})),
     ?_assertEqual(create_data_bag, chef_db:create_fun(#chef_data_bag{})),
     ?_assertEqual(create_environment, chef_db:create_fun(#chef_environment{})),
     ?_assertEqual(create_node, chef_db:create_fun(#chef_node{})),
     ?_assertEqual(create_role, chef_db:create_fun(#chef_role{})),
     ?_assertEqual(create_cookbook_version,
                   chef_db:create_fun(#chef_cookbook_version{}))
    ].

update_fun_test_() ->
    [
     ?_assertEqual(update_data_bag_item, chef_db:update_fun(#chef_data_bag_item{})),
     ?_assertEqual(update_environment, chef_db:update_fun(#chef_environment{})),
     ?_assertEqual(update_node, chef_db:update_fun(#chef_node{})),
     ?_assertEqual(update_role, chef_db:update_fun(#chef_role{})),
     ?_assertEqual(update_cookbook_version,
                   chef_db:update_fun(#chef_cookbook_version{}))
    ].

set_app_env() ->
    test_utils:start_stats_hero(),
    application:set_env(chef_db, couchdb_host, "localhost"),
    application:set_env(chef_db, couchdb_port, 5984).
