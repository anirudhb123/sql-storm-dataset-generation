
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 897 and 897+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'azure' or i_color = 'bisque') and 
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'chiffon') and
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'linen') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'salmon') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'dodger') and 
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'royal') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'orchid') and
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'cream') and
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
