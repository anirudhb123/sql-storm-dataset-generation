
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 858 and 858+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'powder') and 
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'maroon') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burlywood') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'grey') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'metallic') and 
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'seashell') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'blush') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'tan') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
