
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 914 and 914+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'blanched') and 
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'almond') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'white') and
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'orchid') and 
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'bisque') and
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'deep') and
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'indian') and
        (i_units = 'Unknown' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
