
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 956 and 956+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'magenta') and 
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'rose') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'sienna') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'medium') and
        (i_units = 'Oz' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'cornflower') and 
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'ivory') and
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'puff') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'beige') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
