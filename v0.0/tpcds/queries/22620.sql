
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 971 and 971+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'drab') and 
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'indian') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'ivory') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'olive') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'puff') and 
        (i_units = 'Ounce' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'papaya') and
        (i_units = 'Gram' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'lime') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'chiffon') and
        (i_units = 'Tsp' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
