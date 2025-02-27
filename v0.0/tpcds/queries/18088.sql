
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 728 and 728+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'chartreuse') and 
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'cornsilk') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'sandy') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'light') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'bisque') and 
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'papaya') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'puff') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'purple') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
