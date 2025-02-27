
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 972 and 972+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'lavender') and 
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'tomato') and
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'coral') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'khaki') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'navajo') and 
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'green') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'honeydew') and
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'sienna') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
