
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 686 and 686+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'light') and 
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'khaki') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'brown') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'sandy') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'dark') and 
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'navy') and
        (i_units = 'Gram' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'sky') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'lime') and
        (i_units = 'Dozen' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
