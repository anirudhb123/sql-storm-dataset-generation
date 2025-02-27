
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 917 and 917+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'honeydew') and 
        (i_units = 'Gram' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'indian') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'coral') and
        (i_units = 'Tbl' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'cornsilk') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'dark') and 
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'cream') and
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'khaki') and
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
