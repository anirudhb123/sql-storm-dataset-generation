
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 754 and 754+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'deep') and 
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'maroon') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'medium') and
        (i_units = 'N/A' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'ghost') and
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'khaki') and 
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'chocolate') and
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'midnight') and
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'violet') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
