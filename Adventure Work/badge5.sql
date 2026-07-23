-- Badge 5 workshop queries for AGS_GAME_AUDIENCE
-- Co-authored with CoCo

list @uni_kishore/;

CREATE FILE FORMAT FF_JSON_LOGS
    TYPE = JSON
    STRIP_OUTER_ARRAY = TRUE;


select $1 
from @uni_kishore/updated_feed
(file_format => FF_JSON_LOGS);

copy into GAME_LOGS
FROM @uni_kishore/updated_feed
file_format = ( format_name='FF_JSON_LOGS' );



create or replace view ags_game_audience.raw.LOGS as
SELECT 
 RAW_LOG:user_event::TEXT AS USER_EVENT, RAW_LOG:user_login::TEXT as USER_LOGIN
, RAW_LOG:datetime_iso8601::TEXT AS datetime_iso8601 , RAW_LOG:ip_address::text as IP_ADDRESS
, *
FROM GAME_LOGS
where RAW_LOG:ip_address::text is not null;


--looking for empty AGENT column
select * 
from ags_game_audience.raw.LOGS
where RAW_LOG:agent::text is null;

--looking for non-empty IP_ADDRESS column
select 
RAW_LOG:ip_address::text as IP_ADDRESS
,*
from ags_game_audience.raw.LOGS
where RAW_LOG:ip_address::text is not null;


select * from AGS_GAME_AUDIENCE.RAW.LOGS logs 
where USER_LOGIN like '%K%';


select parse_ip('117.216.125.208','inet'):ipv4;


--Look up Kishore and Prajina's Time Zone in the IPInfo share using his headset's IP Address with the PARSE_IP function.
select start_ip, end_ip, start_ip_int, end_ip_int, city, region, country, timezone
from IPINFO_IP_GEOLOC.demo.location
where parse_ip('100.41.16.160', 'inet'):ipv4 --Kishore's Headset's IP Address
BETWEEN start_ip_int AND end_ip_int;

select logs.*,
loc.city,
loc.region,
loc.country,
loc.timezone as GAMER_LTZ_NAME,
convert_timezone('UTC', loc.timezone, logs.datetime_iso8601::TIMESTAMP_NTZ) as game_event_ltz,
dayname(game_event_ltz) as DOW_NAME,
lu.TOD_NAME
from ags_game_audience.raw.LOGS logs
join IPINFO_IP_GEOLOC.demo.location loc
on IPINFO_IP_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
and IPINFO_IP_GEOLOC.public.TO_INT(logs.ip_address)
between start_ip_int and end_ip_int
JOIN ags_game_audience.raw.time_of_day_lu lu 
 on HOUR(game_event_ltz) = lu."HOUR"
;

create or replace table ags_game_audience.enhanced.logs_enhanced as
(
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
from ags_game_audience.raw.LOGS logs
join IPINFO_IP_GEOLOC.demo.location loc
on IPINFO_IP_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
and IPINFO_IP_GEOLOC.public.TO_INT(logs.ip_address)
between start_ip_int and end_ip_int
JOIN ags_game_audience.raw.time_of_day_lu lu 
on HOUR(game_event_ltz) = lu."HOUR"
);

select * from IPINFO_IP_GEOLOC.demo.location;

-- Your role should be SYSADMIN
-- Your database menu should be set to AGS_GAME_AUDIENCE
-- The schema should be set to RAW

--a Look Up table to convert from hour number to "time of day name"
create table ags_game_audience.raw.time_of_day_lu
(  hour number
   ,tod_name varchar(25)
);

--insert statement to add all 24 rows to the table
insert into ags_game_audience.raw.time_of_day_lu
values
(6,'Early morning'),
(7,'Early morning'),
(8,'Early morning'),
(9,'Mid-morning'),
(10,'Mid-morning'),
(11,'Late morning'),
(12,'Late morning'),
(13,'Early afternoon'),
(14,'Early afternoon'),
(15,'Mid-afternoon'),
(16,'Mid-afternoon'),
(17,'Late afternoon'),
(18,'Late afternoon'),
(19,'Early evening'),
(20,'Early evening'),
(21,'Late evening'),
(22,'Late evening'),
(23,'Late evening'),
(0,'Late at night'),
(1,'Late at night'),
(2,'Late at night'),
(3,'Toward morning'),
(4,'Toward morning'),
(5,'Toward morning');


select * from ags_game_audience.raw.time_of_day_lu;

--Check your table to see if you loaded it properly
select tod_name, listagg("HOUR",',') 
from ags_game_audience.raw.time_of_day_lu
group by tod_name;


merge into ags_game_audience.enhanced.logs_enhanced e
using (select logs.ip_address,
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



create or replace TABLE AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS (
	RAW_LOG VARIANT
);


copy into AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS
from @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE 
file_format = ( format_name='FF_JSON_LOGS' );

create OR REPLACE VIEW PL_LOGS AS 
select RAW_LOG:ip_address::TEXT as IP_ADDRESS,
RAW_LOG:user_event::TEXT as USER_EVENT, RAW_LOG:USER_LOGIN as USER_LOGIN,
RAW_LOG:datetime_iso8601::TIMESTAMP_NTZ as DATETIME_ISO8601 , RAW_LOG
from AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS;

--truncate table ags_game_audience.enhanced.logs_enhanced;

select * from ags_game_audience.enhanced.logs_enhanced;


--Step 1 - how many files in the bucket?
list @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE;

--Step 2 - number of rows in raw table (should be file count x 10)
select count(*) from AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS;

--Step 3 - number of rows in raw view (should be file count x 10)
select count(*) from AGS_GAME_AUDIENCE.RAW.PL_LOGS;

--Step 4 - number of rows in enhanced table (should be file count x 10 but fewer rows is okay because not all IP addresses are available from the IPInfo share)
select count(*) from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;