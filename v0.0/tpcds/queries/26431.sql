
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 888 and 888+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'lace') and 
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'antique') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'smoke') and
        (i_units = 'N/A' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'blush') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'burlywood') and 
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'lavender') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'rose') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'dark') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
