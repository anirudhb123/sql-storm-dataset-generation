
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 945 and 945+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'orchid') and 
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'lime') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'yellow') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'chiffon') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'burnished') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'drab') and
        (i_units = 'Bundle' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'antique') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'turquoise') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
