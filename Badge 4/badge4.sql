-- Badge 4: File formats and staging for Zena's Athleisure data
-- Co-authored with CoCo
create or replace table util_db.public.my_data_types
(
  my_number number
, my_text varchar(10)
, my_bool boolean
, my_float float
, my_date date
, my_timestamp timestamp_tz
, my_variant variant
, my_array array
, my_object object
, my_geography geography
, my_geometry geometry
, my_vector vector(int,16)
);

--create database ZENAS_ATHLEISURE_DB


list @PRODUCT_METADATA;

select $1
from @product_metadata; 

create file format zmd_file_format_1
RECORD_DELIMITER = '^';

select $1
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_1);

create file format zmd_file_format_2
FIELD_DELIMITER = '^';  

select $1,$2,$3,$4,$5
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_2);


create or replace file format zmd_file_format_3
FIELD_DELIMITER = '='
RECORD_DELIMITER = '^'; 


create view  zenas_athleisure_db.products.SWEATBAND_COORDINATION as 
select $1 as PRODUCT_CODE, $2 AS HAS_MATCHING_SWEATSUIT
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_3);

create or replace file format zmd_file_format_1
RECORD_DELIMITER = ';';  


select $1 as sizes_available
from @product_metadata/sweatsuit_sizes.txt
(file_format => zmd_file_format_1 );


create view zenas_athleisure_db.products.sweatsuit_sizes as 
select TRIM(REPLACE(s.value, chr(13)||chr(10))) as sizes_available
from @product_metadata/sweatsuit_sizes.txt
(file_format => zmd_file_format_1) as t,
lateral split_to_table(t.$1, ';') as s
where sizes_available <> '';

create or replace file format zmd_file_format_2
FIELD_DELIMITER = '|'
RECORD_DELIMITER = ';'
TRIM_SPACE = TRUE;


create or replace view  zenas_athleisure_db.products.SWEATBAND_PRODUCT_LINE as
select $1 as PRODUCT_CODE, $2 as HEADBAND_DESCRIPTION, $3 as WRISTBAND_DESCRIPTION
from @product_metadata/swt_product_line.txt
(file_format => zmd_file_format_2);

select $1
from @sweatsuits/purple_sweatsuit.png; 

select metadata$filename,coUNT(metadata$file_row_number) AS file_row_number
from @sweatsuits/purple_sweatsuit.png
group by metadata$filename ;




select REPLACE(relative_path, '_', ' ') as no_underscores_filename
, REPLACE(no_underscores_filename, '.png') as just_words_filename
, INITCAP(just_words_filename) as product_name
from directory(@sweatsuits);



select INITCAP(replace(REPLACE(relative_path, '_', ' '),'.png')) as product_name
from directory(@sweatsuits);


--create an internal table for some sweatsuit info
create or replace table zenas_athleisure_db.products.sweatsuits (
	color_or_style varchar(25),
	file_name varchar(50),
	price number(5,2)
);

select * from zenas_athleisure_db.products.sweatsuits


select * from zenas_athleisure_db.products.sweatsuits;


create or replace view  PRODUCT_LIST as
select INITCAP(replace(REPLACE(relative_path, '_', ' '),'.png')) as product_name , *
from directory(@sweatsuits) d
join sweatsuits s 
on d.RELATIVE_PATH = s.FILE_NAME
;


select * from PRODUCT_LIST;

create view CATALOG as
select * 
from product_list p
cross join sweatsuit_sizes;

-- Add a table to map the sweatsuits to the sweat band sets
create table zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style varchar(25)
,upsell_product_code varchar(10)
);

--populate the upsell table
insert into zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style
,upsell_product_code 
)
VALUES
('Charcoal Grey','SWT_GRY')
,('Forest Green','SWT_FGN')
,('Orange','SWT_ORG')
,('Pink', 'SWT_PNK')
,('Red','SWT_RED')
,('Yellow', 'SWT_YLW');



select * from zenas_athleisure_db.products.upsell_mapping;

-- Zena needs a single view she can query for her website prototype
create view catalog_for_website as 
select color_or_style
,price
,file_name
, get_presigned_url(@sweatsuits, file_name, 3600) as file_url
,size_list
,coalesce('Consider: ' ||  headband_description || ' & ' || wristband_description, 'Consider: White, Black or Grey Sweat Accessories')  as upsell_product_desc
from
(   select color_or_style, price, file_name
    ,listagg(sizes_available, ' | ') within group (order by sizes_available) as size_list
    from catalog
    group by color_or_style, price, file_name
) c
left join upsell_mapping u
on u.sweatsuit_color_or_style = c.color_or_style
left join sweatband_coordination sc
on sc.product_code = u.upsell_product_code
left join sweatband_product_line spl
on spl.product_code = sc.product_code;


select * from catalog_for_website ;



