-record(etsdb_store_req_v1,{bucket::module(),value::term(),timestamp::non_neg_integer(),req_id::term()}).
-record(etsdb_innerstore_req_v1,{value,req_id::term()}).
-record(etsdb_get_cell_req_v1,{bucket::module(),value,filter,req_id::term()}).

-define(ETSDB_STORE_REQ, #etsdb_store_req_v1).
-define(ETSDB_INNERSTORE_REQ, #etsdb_innerstore_req_v1).
-define(ETSDB_GET_CELL_REQ, #etsdb_get_cell_req_v1).