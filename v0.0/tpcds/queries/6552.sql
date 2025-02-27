
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 887 and 887+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'thistle') and 
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'chartreuse') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'lawn') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'tan') and
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'orchid') and 
        (i_units = 'Oz' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'midnight') and
        (i_units = 'Case' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'turquoise') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'steel') and
        (i_units = 'Gram' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
