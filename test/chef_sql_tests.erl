-module(chef_sql_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("chef_objects/include/chef_types.hrl").

%% Used in testing flatten_record
-record(test_record, {'field1',
                      'field2'
                     }).

flatten_record_test_() ->
    [{"flatten record of simple record is ok",
        fun() ->
            R = #test_record{field1= <<"foo">>,
                         field2= <<"bar">> },
            Got = chef_sql:flatten_record(R),
            ?assertEqual([<<"foo">>, <<"bar">>], Got)
        end
      },
      {"throw on undefined as a default value",
        fun() ->
            R = #test_record{field1= <<"foo">>},
            ?assertError({undefined_in_record, R},
                         chef_sql:flatten_record(R))
        end
      },
      {"throw on explicit undefined used as a value",
        fun() ->
            R = #test_record{field1= <<"foo">>, field2= undefined},
            ?assertError({undefined_in_record, R},
                         chef_sql:flatten_record(R))
        end
      }
    ].

%% Sandbox Tests

sandbox_rows() ->
  [
   [{<<"sandbox_id">>, <<"deadbeefdeadbeefdeadbeefdeadbeef">>},
    {<<"org_id">>, <<"abad1deaabad1deaabad1deaabad1dea">>},
    {<<"created_at">>, {{2012,4,25},{3,7,43.0}}},
    {<<"checksum">>, <<"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa">>},
    {<<"uploaded">>, false}],
   [{<<"sandbox_id">>, <<"deadbeefdeadbeefdeadbeefdeadbeef">>},
    {<<"org_id">>, <<"abad1deaabad1deaabad1deaabad1dea">>},
    {<<"created_at">>, {{2012,4,25},{3,7,43.0}}},
    {<<"checksum">>, <<"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb">>},
    {<<"uploaded">>, true}],
   [{<<"sandbox_id">>, <<"deadbeefdeadbeefdeadbeefdeadbeef">>},
    {<<"org_id">>, <<"abad1deaabad1deaabad1deaabad1dea">>},
    {<<"created_at">>, {{2012,4,25},{3,7,43.0}}},
    {<<"checksum">>, <<"cccccccccccccccccccccccccccccccc">>},
    {<<"uploaded">>, false}],
   [{<<"sandbox_id">>, <<"deadbeefdeadbeefdeadbeefdeadbeef">>},
    {<<"org_id">>, <<"abad1deaabad1deaabad1deaabad1dea">>},
    {<<"created_at">>, {{2012,4,25},{3,7,43.0}}},
    {<<"checksum">>, <<"dddddddddddddddddddddddddddddddd">>},
    {<<"uploaded">>, true}]
  ].

sandbox_join_rows_to_record_test_() ->
    [
     {"Condenses several sandboxed checksum rows into a single sandbox record",
      fun() ->
              ?assertEqual(chef_sql:sandbox_join_rows_to_record(sandbox_rows()),
                           #chef_sandbox{id = <<"deadbeefdeadbeefdeadbeefdeadbeef">>,
                                         org_id = <<"abad1deaabad1deaabad1deaabad1dea">>,
                                         created_at = {{2012,4,25},{3,7,43.0}},
                                         checksums = [
                                                      {<<"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa">>, false},
                                                      {<<"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb">>, true},
                                                      {<<"cccccccccccccccccccccccccccccccc">>, false},
                                                      {<<"dddddddddddddddddddddddddddddddd">>, true}
                                                     ]})
      end}
    ].