%%%-------------------------------------------------------------------
%% @doc dbmgr interface supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(dbmgr_interface_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
  SupFlags = #{strategy => one_for_one,
               intensity => 10,
               period => 10},
  ChildSpecs = [
               
               
               %,#{id => dbmgr_kafka_producer, start => {dbmgr_kafka_producer, start_link, []}}
               %,#{id => dbmgr_kafka_consumer, start => {dbmgr_kafka_consumer, start_link, []}}
               #{id => dbmgr_if_cassandra_node_sofo, start => {dbmgr_if_cassandra_node_sofo,
                                                                 start_link, []}, type => supervisor}
               ,#{id => dbmgr_if_cassandra_nodes, start => {dbmgr_if_cassandra_nodes, start_link, []}}
               ,#{id => dbmgr_cassandra, start => {dbmgr_cassandra, start_link, []}}
               ,#{id => dbmigration, start => {dbmigration, start_link, []}}

               ],
  {ok, {SupFlags, ChildSpecs}}.

%% internal functions
