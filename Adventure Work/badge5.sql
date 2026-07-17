
list @uni_kishore/kickoff;

CREATE FILE FORMAT FF_JSON_LOGS
    TYPE = JSON
    STRIP_OUTER_ARRAY = TRUE;


select $1 
from @uni_kishore/kickoff
(file_format => FF_JSON_LOGS);

copy into GAME_LOGS
FROM @uni_kishore/kickoff
file_format = ( format_name='FF_JSON_LOGS' );

select * from logs;


create or replace view LOGS as
SELECT RAW_LOG:agent::TEXT AS AGENT
, RAW_LOG:user_event::TEXT AS USER_EVENT
, RAW_LOG:datetime_iso8601::TEXT AS datetime_iso8601
, *
FROM GAME_LOGS;


