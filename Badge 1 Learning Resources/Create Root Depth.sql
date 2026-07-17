-- Garden plants tables and data loading scripts
-- Co-authored with CoCo
select * from root_depth

create table garden_plants.veggies.vegetable_details
(
plant_name varchar(25)
, root_depth_code varchar(1)    
);



select * from veggies.vegetable_details
where plant_name = 'Spinach' and root_depth_code = 'D'


delete from veggies.vegetable_details
where plant_name = 'Spinach' and root_depth_code = 'D'

create or replace TABLE FRUIT_DETAILS (
	PLANT_NAME VARCHAR(25),
	ROOT_DEPTH_CODE VARCHAR(1)
);

create or replace table garden_plants.veggies.vegetable_details_soil_type
( plant_name varchar(25)
 ,soil_type number(1,0)
);

create file format garden_plants.veggies.PIPECOLSEP_ONEHEADROW 
    type = 'CSV'--csv is used for any flat file (tsv, pipe-separated, etc)
    field_delimiter = '|' --pipes as column separators
    skip_header = 1 --one header row to skip
    ;


copy into garden_plants.veggies.vegetable_details_soil_type
from @util_db.public.MY_INTERNAL_STGAE
files = ( 'VEG_NAME_TO_SOIL_TYPE_PIPE.txt')
file_format = ( format_name=GARDEN_PLANTS.VEGGIES.PIPECOLSEP_ONEHEADROW );


    create file format garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW 
    TYPE = 'CSV'--csv for comma separated files
    FIELD_DELIMITER = ',' --commas as column separators
    SKIP_HEADER = 1 --one header row  
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
--this means that some values will be wrapped in double-quotes bc they have commas in them
    ;

--The data in the file, with no FILE FORMAT specified
select $1
from @util_db.public.MY_INTERNAL_STGAE/LU_SOIL_TYPE.tsv;

--Same file but with one of the file formats we created earlier  
select $1, $2, $3
from @util_db.public.MY_INTERNAL_STGAE/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW);

--Same file but with the other file format we created earlier
select $1, $2, $3
from @util_db.public.MY_INTERNAL_STGAE/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.PIPECOLSEP_ONEHEADROW );


create file format garden_plants.veggies.L9_CHALLENGE_FF
    TYPE = 'CSV'--csv is used for any flat file (tsv, pipe-separated, etc)
    FIELD_DELIMITER = '\t' --tabs as column separators for TSV
    SKIP_HEADER = 1 --one header row
    ;   

SELECT $1,$2,$3
from @util_db.public.MY_INTERNAL_STGAE/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.L9_CHALLENGE_FF);


create or replace table LU_SOIL_TYPE(
SOIL_TYPE_ID number,	
SOIL_TYPE varchar(15),
SOIL_DESCRIPTION varchar(75)
);

create or replace table LU_SOIL_TYPE (
SOIL_TYPE_ID number,
SOIL_TYPE varchar(15),
SOIL_DESCRIPTION varchar(75)
);


copy into garden_plants.veggies.LU_SOIL_TYPE
from @util_db.public.MY_INTERNAL_STGAE
files = ( 'LU_SOIL_TYPE.tsv')
file_format = ( format_name=garden_plants.veggies.L9_CHALLENGE_FF );

select * from garden_plants.veggies.LU_SOIL_TYPE

create or replace table VEGETABLE_DETAILS_PLANT_HEIGHT (
PLANT_NAME varchar(75),
UOM varchar(15),
LOW_END_OF_RANGE number,
HIGH_END_OF_RANGE number
);


create file format garden_plants.veggies.VEGETABLE_DETAILS_PLANT_HEIGHT
    type = 'CSV'--csv is used for any flat file (tsv, pipe-separated, etc)
    field_delimiter = ',' --COMMA as column separators
    skip_header = 1 --one header row to skip
    ;


select * from garden_plants.veggies.VEGETABLE_DETAILS_PLANT_HEIGHT
