%% -------------------------------------------------------------------
%%
%%
%% Copyright (c) Dreyk.  All Rights Reserved.
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

%% @doc Simple implementation tsdb bucket for storing any data in {id,time} order
-module(etsdb_tkb).



-export([
		 api_version/0,
		 w_val/0,
		 r_val/0,
		 w_quorum/0,
		 r_quorum/0,
		 make_partitions/1,
		 serialize/2,
		 scan_partiotions/2,
		 scan_spec/3,
		 join_scan/2]).

-behaviour(etsdb_bucket).

-author('Alex G. <gunin@mail.mipt.ru>').

-define(REGION_SIZE,86400000). %%One Day

api_version()->
	"0.1".

w_val()->
	3.
r_val()->
	3.
w_quorum()->
	2.
r_quorum()->
	2.

make_partitions(Datas) when is_list(Datas)->
	[{make_partition(Data),Data}||Data<-Datas];
make_partitions(Data)->
	[{make_partition(Data),Data}].

make_partition({{ID,Time},_Value})->
	TimeRegion = Time div ?REGION_SIZE,
	partiotion_by_region(ID,TimeRegion).

scan_partiotions({ID,Time1},{ID,Time2})->
	FromTimeRegion = Time1 div ?REGION_SIZE,
	ToTimeRegion = Time2 div ?REGION_SIZE,
	lists:usort([partiotion_by_region(ID,TimeRegion)||TimeRegion<-lists:seq(FromTimeRegion,ToTimeRegion)]).

serialize(Datas,ForBackEnd) when is_list(Datas)->
	[serialize_internal(Data,ForBackEnd)||Data<-Datas];
serialize(Data,ForBackEnd)->
	serialize_internal(Data,ForBackEnd).

serialize_internal({{ID,Time},Value},etsdb_leveldb_backend)->
	Value1 = term_to_binary(Value),
	{<<ID:64/integer,Time:64/integer>>,<<Value1/binary>>};
serialize_internal({{ID,Time},Value},_ForBackEnd)->
	{{ID,Time},Value}.
partiotion_by_region(ID,TimeRegion)->
	<<ID:64/integer,TimeRegion:64/integer>>.

scan_spec({ID,From},{ID,To},_BackEnd)->
	StartKey = <<ID:64/integer,From:64/integer>>,
	StopKey = <<ID:64/integer,To:64/integer>>,
	lager:info("scan ~p",[ID,From,To]),
	Fun = fun
			 ({K,_}=V, Acc) when K >= StartKey andalso K =< StopKey ->	  
				  case unserialize_internal(V) of
					  skip->
						  Acc;
					  {error,not_object}->
						  throw({break, Acc});
					  UserData->
						  [UserData|Acc]
				  end;
			 (_V, Acc)->
				  throw({break,Acc})
		  end,
	{StartKey,Fun}.

unserialize_internal({_,<<"deleted">>})->
	skip;
unserialize_internal({<<ID:64/integer,Time:64/integer>>,<<Value/binary>>})->
	{{ID,Time},binary_to_term(Value)};
unserialize_internal(_)->
	{error,not_object}.

join_scan(A1,A2)->
	orddict:merge(fun(_,V1,_)->V1 end,A1,A2).