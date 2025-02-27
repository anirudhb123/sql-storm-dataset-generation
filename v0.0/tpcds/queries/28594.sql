
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 955 and 955+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'sienna') and 
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'deep') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'brown') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'blanched') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'salmon') and 
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'almond') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'peru') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'mint') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
