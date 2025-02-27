
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 869 and 869+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'peach') and 
        (i_units = 'Bunch' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'khaki') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'dodger') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'burlywood') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'goldenrod') and 
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'sienna') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'chiffon') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'green') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
