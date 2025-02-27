
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 898 and 898+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'ivory') and 
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'peach') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'khaki') and
        (i_units = 'Each' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'tan') and
        (i_units = 'Pallet' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'lime') and 
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'misty') and
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'almond') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'hot') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
