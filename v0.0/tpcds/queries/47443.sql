
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 927 and 927+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'magenta') and 
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'plum') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'brown') and
        (i_units = 'Gross' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'orchid') and
        (i_units = 'N/A' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'chartreuse') and 
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'maroon') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'blanched') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
