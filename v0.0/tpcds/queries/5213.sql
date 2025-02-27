
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 740 and 740+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lime' or i_color = 'linen') and 
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'gainsboro') and
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'papaya') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'wheat') and
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'midnight') and 
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'orange') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'mint') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'lemon') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
