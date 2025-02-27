
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 743 and 743+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'linen') and 
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'burnished') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'dodger') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'bisque') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'powder') and 
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'tan') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'green') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'rose') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
