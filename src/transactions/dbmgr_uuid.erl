-module(dbmgr_uuid).  % Replace my_gen_server with your module name
-behaviour(gen_server).

%% API
-export([start_link/0, stop/0]). % Add other API functions as needed

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-export([]).


-export([time_uuid/0]).
%%===================================================================
%%% API

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []). % Adjust args as needed

stop() ->
  gen_server:call(?MODULE, stop).

time_uuid() ->
  gen_server:call(?MODULE, time_uuid).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->  % Initialization; replace [] with arguments if necessary
  {ok, #{}, 0}.  % Replace #state{} with your initial state

handle_call(time_uuid, _From, State) ->
  {Reply, NewState} = create_time_uuid(State),
  {reply, Reply, NewState};
handle_call(stop, _From, State) ->
  {stop, normal, ok, State}; % Graceful shutdown
handle_call(_Request, _From, State) ->
  Reply = {error, unknown_request},  % Handle other calls here
  {reply, Reply, State}.


handle_cast(_Msg, State) -> % Handle asynchronous messages
  {noreply, State}.

handle_info(timeout, State) ->
  StateU = create_time_uuid(State),
  {noreply, StateU};
handle_info(_Info, State) -> % Handle timeouts, other messages
  {noreply, State}.

terminate(_Reason, _State) ->  % Cleanup before termination
  ok.

code_change(_OldVsn, State, _Extra) ->  % For hot code swapping
  {ok, State}.

%%%===================================================================
%%% Internal functions and state definition
%%%===================================================================

create_time_uuid(State) ->
  case maps:size(State)> 0 of
    true ->
      State1 = maps:get(uuid_state, State),
      {UUID, NewState} = uuid:get_v1(State1),
      {list_to_binary(uuid:uuid_to_string(UUID))
       ,#{uuid_state => NewState}};
    false ->
     StateU = uuid:new(self()),
     {_UUID, NewState} = uuid:get_v1(StateU),
     #{uuid_state => NewState}
end.