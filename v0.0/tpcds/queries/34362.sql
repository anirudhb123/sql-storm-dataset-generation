
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 668 and 668+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'light') and 
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'sienna') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'orchid') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'burnished') and 
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'powder') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'khaki') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'lace') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
