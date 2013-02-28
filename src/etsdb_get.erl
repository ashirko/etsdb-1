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
-module(etsdb_get).

-export([scan/3]).

-define(DEFAULT_TIMEOUT,60000).

scan(Bucket,From,To)->
	Partitions = Bucket:scan_partiotions(From,To),
	scan_partiotions(Bucket,From,To,Partitions,[]).

scan_partiotions(_Bucket,_From,_To,[],Acc)->
	Acc;
scan_partiotions(Bucket,From,To,[Partition|T],Acc)->
	ReqRef = make_ref(),
	Me = self(),
	PartionIdx = crypto:sha(Partition),
	etsdb_get_fsm:start_link({raw,ReqRef,Me},PartionIdx, Bucket, {scan,From,To},?DEFAULT_TIMEOUT),
	Res = wait_for_results(ReqRef,?DEFAULT_TIMEOUT),
	scan_partiotions(Bucket,From,To,T,[Res++Acc]).

wait_for_results(ReqRef,Timeout)->
	receive 
		{ReqRef,Res}->
			Res
	after Timeout->
			{error,timeot}
	end.