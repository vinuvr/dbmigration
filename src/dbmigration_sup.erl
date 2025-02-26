%%%-------------------------------------------------------------------
%% @doc dbmigration top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(dbmigration_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

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
    SupFlags = #{strategy => one_for_all,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [#{id => dbmgr_uuid, start => {dbmgr_uuid, start_link, []}}
                   ,#{id => dbmgr_interface_sup, start => {dbmgr_interface_sup, start_link, []}}
                %   ,#{id => dbmgr_if_cassandra_node_sofo, start => {dbmgr_if_cassandra_node_sofo, start_link, []}} 
                %   ,#{id => dbmgr_if_cassandra_nodes, start => {dbmgr_if_cassandra_nodes, start_link, []}}
                %   ,#{id=> dbmgr_cassandra, start => {dbmgr_cassandra, start_link, []}}
                %   ,#{id => dbmigration, start => {dbmigration, start_link, []}} 
                  %%dbmgr_cassandra:start_link().
                  %%dbmgr_if_cassandra_nodes:start_link().

                   %%dbmgr_if_cassandra_node_sofo:start_link().    

],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
