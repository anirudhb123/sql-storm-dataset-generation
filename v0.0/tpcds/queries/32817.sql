
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 999 and 999+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'azure') and 
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'lawn') and
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'misty') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'puff') and
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'deep') and 
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'navy') and
        (i_units = 'Bundle' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'steel') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'ghost') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
