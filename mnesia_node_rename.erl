%%%-------------------------------------------------------------------
%%% @author  <zhangjianao@gmail.com>
%%% @copyright free
%%%
%%% README
%%% This tool is used to replace node name in mnesia schema to another node name.
%%% Sometimes I need to move mnesia db form one machine to another.
%%% This is the steps:
%%% 1. copy all files in mnesia dir to another node.
%%% On new node:
%%% 2. backup "schema.DAT" file, !!!!!this is very important!!!!!
%%% 3. shell> erl
%%% 4. c(mnesia_node_rename).
%%% 5. mnesia_node_rename:start("/path/to/schema.DAT", "old_node_name", "new_node_name").
%%% Then, start new mnesia node.
%%% 
%%% PROBLEM
%%% This tool use a very robust way to do the rename:
%%% It convert each row to String, use RE to replace, and convert back.
%%% So if the "old_node_name" can match some other things, there will be a problem.
%%% To be sure, use "mnesia_node_rename:view("/path/to/schema.DAT")." to see before rename.
%%% If the schema.DAT mess up, use the backup at step 2.
%%%
%%% Good Luck
%%%-------------------------------------------------------------------
-module(mnesia_node_rename).

%% API
-export([start/3,view/1]).

%%%===================================================================
%%% API
%%%===================================================================
start(SchemaFile, OldNode, NewNode) ->
    {ok, N} = dets:open_file(schema, [{file, SchemaFile},{repair,false}, {keypos, 2}]),
    rename(N, dets:first(N), {OldNode, NewNode}),
    dets:close(N).

view(SchemaFile) ->
    {ok, N} = dets:open_file(schema, [{file, SchemaFile},{repair,false}, {keypos, 2}]),
    dets:traverse(N, fun(X) -> io:format("~p~n", [X]), continue end),
    dets:close(N).
    
%%%===================================================================
%%% Internal functions
%%%===================================================================
rename(_Dets, '$end_of_table', _) ->
    io:format("~nrename complete.~n",[]);
rename(Dets, Key, {OldNode, NewNode}) ->
    [Row] = dets:lookup(Dets, Key),
    Str = io_lib:format("~w", [Row]),
    New = re:replace(Str, OldNode, NewNode, [global, {return, list}]),

    {ok,Tokens,_} = erl_scan:string(New++"."),
    {ok,Term} = erl_parse:parse_term(Tokens),
    dets:insert(Dets, [Term]),
    io:format("~p~n", [Term]),
    rename(Dets, dets:next(Dets, Key), {OldNode, NewNode}).
