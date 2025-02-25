-module(dbmigration).  % Replace my_gen_server with your module name
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

-export([start_dbmigration/1
         ,add_to_chat_messages_core/1]).

-export([year_month/1]).
%===================================================================
%%% API

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []). % Adjust args as needed

stop() ->
  gen_server:call(?MODULE, stop).

start_dbmigration(Args) ->
  gen_server:call(?MODULE, {start_dbmigration, Args}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->  % Initialization; replace [] with arguments if necessary
  {ok, #{}}.  % Replace #state{} with your initial state

handle_call({start_dbmigration, Args}, _From, State) ->
  do_start_dbmigration(Args),
  {reply, ok, State};
handle_call(stop, _From, State) ->
  {stop, normal, ok, State}; % Graceful shutdown
handle_call(_Request, _From, State) ->
  Reply = {error, unknown_request},  % Handle other calls here
  {reply, Reply, State}.


handle_cast(_Msg, State) -> % Handle asynchronous messages
  {noreply, State}.

handle_info(_Info, State) -> % Handle timeouts, other messages
  {noreply, State}.

terminate(_Reason, _State) ->  % Cleanup before termination
  ok.

code_change(_OldVsn, State, _Extra) ->  % For hot code swapping
  {ok, State}.

%%%===================================================================
%%% Internal functions and state definition
%%%===================================================================

do_start_dbmigration(Args) ->
  lager:info("start_dbmigration ~p", [Args]),
  lists:foreach(
    fun(#{a_ctime := Actime, attachments := Attachments, body := Body
          ,category := Category, delivered_to := DeliveredTo, edited_time := EditedTime
          ,fcm_notification := FN, forward_from := ForwardedFrom
          ,from := From, group := Group, is_seen := IsSeen
          ,other_info_map := OtherInfoMap, parent_message := Parent_message
          ,pinned := Pinned, pinned_by := Pinnedby
          ,pinned_time := PinnedTime, platform := Platform
          ,reactions := Reactions, reply_to := Replyto
          ,schedule_time := ScheduleTime, seen := Seen
          ,status := Status, tenant := Tenant
          ,to := To, type := Type})->
        #{<<"plainText">> := Plaintext} = Body,
        Uuid = dbmgr_uuid:time_uuid(),
        CID = conversation_id(To, From),
        spawn(fun() ->
                  add_to_chat_messages_core(#{tenant_id => Tenant
                                              ,conversation_id => CID
                                              ,year_month => year_month(Actime)
                                              ,uuid => Uuid
                                              ,sender_id => From
                                              ,recipient_id => To
                                              ,type => Type
                                              ,category => Category
                                              ,status => Status
                                              ,is_pinned => Pinned
                                              ,is_group => Group
                                              ,is_seen => IsSeen
                                              ,a_ctime => Actime
                                              ,body => jsx:encode(Body)
                                              ,plaintext => Plaintext})
              end),

        spawn(fun() -> add_pinned_messages(dbmgr_api_utils:filtered_map(
                                             #{conversation_id => CID
                                               ,message_id => Uuid
                                               ,pinned_time => PinnedTime
                                               ,pinned_user_id => Pinnedby
                                               ,is_pinned => Pinned
                                              })) end),
        lists:foreach(
          fun(#{clientid := DUserId, time := DTime}) ->
              spawn(fun() ->
                        DeliveredMap = dbmgr_api_utils:filtered_map(
                                         #{uuid => dbmgr_api_utils:uuid_bin(),
                                           message_id => Uuid,
                                           delivered_to_user_id => DUserId,
                                           delivered_time => DTime}),
                        add_delivered_to(DeliveredMap)
                    end);
             (_) -> ok
          end, DeliveredTo),

        lists:foreach(fun(#{timestamp := STime, uuid := SUserId}) ->
                          spawn(fun() ->
                                    SeenMap = dbmgr_api_utils:filtered_map(
                                                #{uuid => dbmgr_api_utils:uuid_bin(),
                                                  message_id => Uuid,
                                                  seen_user_id => SUserId,
                                                  seen_time => STime}),
                                    lager:info("got seen by"),
                                    add_seen_by(SeenMap)
                                end);
                         (_) -> ok
                      end, Seen),

        lager:info("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"),
        lists:foreach(
          fun(#{emoji := Emoji, member := Members, count := Count}) ->
              spawn(fun()->
                        lists:foreach(
                          fun(Member) ->
                              spawn(fun() ->
                                        ReactionMap = dbmgr_api_utils:filtered_map(
                                                        #{uuid => dbmgr_api_utils:uuid_bin(),
                                                          message_id => Uuid,
                                                          user_id => Member,
                                                          emoji => Emoji,
                                                          reaction_time => erlang:system_time(millisecond)
                                                         }),
                                        add_chat_message_user_reactions(ReactionMap)
                                    end);
                             (Otherss) -> lager:info("got the unkown ~p",[Otherss])
                          end, Members),
                        ReactionCountMap = dbmgr_api_utils:filtered_map(
                                             #{message_id => Uuid,
                                               emoji => Emoji,
                                               count => Count}),
                        add_chat_message_reaction_counts(ReactionCountMap)
                    end);
             (OOOO) -> lager:info("Got dddddddddddd ~p",[OOOO])
          end, Reactions);


        % ReactionMap = dbmgr_api_utils:filtered_map(
        % #{uuid => dbmgr_api_utils:uuid_bin(),
        %  message_id => Uuid,
        %  user_id => })
        %   ),
        %   add_chat_message_reaction_counts(ReactionCountMap)

       (Other) -> lager:info("got unknown ~p",[Other])
    end,
    Args).

% add_to_kass(Args),
%   spawn(fun() -> add_to_chat_messages_core(Args) end), %add_to_chat_messages_core(Args),
%   add_pinned_messages(Args),
%   add_delivered_to(Args),
%   add_seen_by(Args),
%   add_chat_message_user_reactions(Args),
%   add_chat_message_attachments(Args),
%   add_chat_message_additional(Args),
%   ok.
% time_uuid() ->
%   State = uuid:new(self()),
%   {UUID, _NewState} = uuid:get_v1(State),
%   list_to_binary(uuid:uuid_to_string(UUID)).

year_month(Actime) ->
  %{{Y, M, _}, _} = calendar:gregorian_days_to_date(Actime),
  {{Y, M,_ }, _} = calendar:system_time_to_universal_time(Actime, millisecond),
  case Y of
    Y when Y > 10 -> "0" ++ dbmgr_api_utils:to(list, M) ++ dbmgr_api_utils:to(list, Y);
    _ -> dbmgr_api_utils:to(list, M) ++ dbmgr_api_utils:to(list, Y)
  end.
%io_lib:format("~p-~p", [M, Y]).

conversation_id(To, From) ->
  S = lists:sort([To, From]),
  Hash = crypto:hash(sha256, io_lib:format("~p-~p", S)),
  <<A:32, B:16, C:16, D:16, E:48>> = binary:part(Hash, 0, 16),
  C1 = (C band 16#0FFF) bor (5 bsl 12),   % Apply version 5
  D1 = (D band 16#3FFF) bor (2 bsl 14),   % Apply variant
  UUID = <<A:32, B:16, C1:16, D1:16, E:48>>,
  list_to_binary(uuid:uuid_to_string(UUID)).


add_to_chat_messages_core(Args) ->
  %lager:info("add_to_chat_messages_core ~p", [Args]),
  Query = dbmgr_api_utils:cassandra_put_query(chat_messages_core, Args),
  R = dbmgr_cassandra:query(Query),
  lager:info("add_to_chat_message result ~p and query ~p", [R, Query]).

add_pinned_messages(#{is_pinned := false}) ->
  ok;
add_pinned_messages(Args) ->
  lager:info("p1inned_messages ~p", [Args]),
  Query = dbmgr_api_utils:cassandra_put_query(pinned_messages, maps:remove(is_pinned, Args)),
  R = dbmgr_cassandra:query(Query),
  lager:info("pinned_messages result  ~p and query ~p", [R, Query]).

add_delivered_to(Args) ->
  %lager:info("delivered_to ~p", [Args]),
  Query = dbmgr_api_utils:cassandra_put_query(delivered_to, Args),
  R = dbmgr_cassandra:query(Query),
  lager:info("delivered_to result  ~p and query ~p", [R, Query]).

add_seen_by(Args) ->
  lager:info("seen_by ~p", [Args]),
  Query = dbmgr_api_utils:cassandra_put_query(seen_by, Args),
  R = dbmgr_cassandra:query(Query),
  lager:info("seen_by resutl  ~p and query ~p", [R, Query]).

add_chat_message_user_reactions(Args) ->
  lager:info("chat_message_user_reactions ~p", [Args]),
  Query = dbmgr_api_utils:cassandra_put_query(chat_message_user_reactions, Args),
  R = dbmgr_cassandra:query(Query),
  lager:info("chat_message_user_reactions result  ~p and query ~p", [R, Query]).

add_chat_message_reaction_counts(Args) ->
  lager:info("got chat message reactions count"),
  Query = dbmgr_api_utils:cassandra_put_query(chat_message_reaction_counts, Args),
  R = dbmgr_cassandra:query(Query),
  lager:info("chat_message_reaction_counts result ~p and query ", [R, Query]).

add_chat_message_attachments(Args) ->
  lager:info("chat_message_attachments ~p", [Args]),
  R = dbmgr_api_utils:cassandra_put_query(chat_message_attachments, Args),
  lager:info("chat_message_attachments  ~p", [R]).

add_chat_message_additional(Args) ->
  lager:info("chat_message_additional ~p", [Args]),
  R = dbmgr_api_utils:cassandra_put_query(chat_message_additional, Args),
  lager:info("chat_message_additional  ~p", [R]).
