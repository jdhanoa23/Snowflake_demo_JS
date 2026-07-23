create or replace task GET_NEW_FILES
    warehouse = 'COMPUTE_WH'
    schedule = '10 Minutes'
    -- <session_parameter> = <value> [ , <session_parameter> = <value> ... ]
    -- user_task_timeout_ms = <num>
    -- copy grants
    -- comment = '<comment>'
    -- after <string>
  -- when <boolean_expr>
  as
    copy into AGS_GAME_AUDIENCE.RAW. PL_GAME_LOGS
from @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE 
file_format = ( format_name='FF_JSON_LOGS' );

execute task GET_NEW_FILES;

USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL';

--Change the SCHEDULE for GET_NEW_FILES so it runs more often
schedule='5 Minutes'

--Remove the SCHEDULE property and have LOAD_LOGS_ENHANCED run  
--each time GET_NEW_FILES completes
after AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES;

--Turning on a task is done with a RESUME command
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES resume;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED resume;

--Turning OFF a task is done with a SUSPEND command
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES suspend;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED suspend;


create or replace task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
	after AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
	as
Merge into ags_game_audience.enhanced.logs_enhanced e
using (
select logs.ip_address,
logs.user_login as GAMER_NAME,
logs.user_event as GAME_EVENT_NAME,
logs.datetime_iso8601 as GAME_EVENT_UTC,
loc.city,
loc.region,
loc.country,
loc.timezone as GAMER_LTZ_NAME,
convert_timezone('UTC', loc.timezone, logs.datetime_iso8601::TIMESTAMP_NTZ) as game_event_ltz,
dayname(game_event_ltz) as DOW_NAME,
lu.TOD_NAME
from ags_game_audience.raw.PL_LOGS logs
join IPINFO_IP_GEOLOC.demo.location loc
on IPINFO_IP_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
and IPINFO_IP_GEOLOC.public.TO_INT(logs.ip_address)
between start_ip_int and end_ip_int
JOIN ags_game_audience.raw.time_of_day_lu lu 
on HOUR(game_event_ltz) = lu."HOUR") r
On r.gamer_name = e.GAMER_NAME
and r.game_event_utc = e.game_event_utc
and r.game_event_name = e.game_event_name

when not matched then 
insert (ip_address,GAMER_NAME,GAME_EVENT_NAME, game_event_utc, city, region, country, GAMER_LTZ_NAME,game_event_ltz,  DOW_NAME,TOD_NAME)

values (r.ip_address, r.GAMER_NAME, r.GAME_EVENT_NAME, r.GAME_EVENT_UTC, r.city, r.region, r.country, r.GAMER_LTZ_NAME, r.game_event_ltz,r.DOW_NAME, r.TOD_NAME);

;