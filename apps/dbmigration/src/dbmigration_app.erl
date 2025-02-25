%%%-------------------------------------------------------------------
%% @doc dbmigration public API
%% @end
%%%-------------------------------------------------------------------

-module(dbmigration_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    dbmigration_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
