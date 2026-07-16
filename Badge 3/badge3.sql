-- SQL setup for Smoothies database, tables, and order management
-- Co-authored with CoCo
create database SMOOTHIES

create table FRUIT_OPTIONS
(
FRUIT_ID number
, FRUIT_NAME varchar(25)   
);

select * from FRUIT_OPTIONS

create file format smoothies.public.two_headerrow_pct_delim
  type = CSV,
  skip_header = 2,
  field_delimiter = '%',
  trim_space = TRUE
;

copy into FRUIT_OPTIONS
from @util_db.public.MY_INTERNAL_STGAE
files = ( 'fruits_available_for_smoothies.txt')
file_format = ( format_name=smoothies.public.two_headerrow_pct_delim);

create table SMOOTHIES.PUBLIC.ORDERS
(ingredients varchar(200)
) ;

 insert into smoothies.public.orders(ingredients)
                    values ('Cantaloupe Guava Jackfruit Elderberries Figs')

select * from SMOOTHIES.PUBLIC.ORDERS

--truncate table SMOOTHIES.PUBLIC.ORDERS

alter table SMOOTHIES.PUBLIC.ORDERS 
add column order_filled boolean default FALSE;

alter table SMOOTHIES.PUBLIC.ORDERS 
add column order_uid integer --adds the column
default smoothies.public.order_seq.nextval  --sets the value of the column to sequence
constraint order_uid unique enforced; --makes sure there is always a unique value in the column


create or replace table smoothies.public.orders (
       order_uid integer default smoothies.public.order_seq.nextval,
       order_filled boolean default false,
       name_on_order varchar(100),
       ingredients varchar(200),
       constraint order_uid unique (order_uid),
       order_ts timestamp_ltz default current_timestamp()
);


