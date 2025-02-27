
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 827 and 827+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'gainsboro') and 
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'turquoise') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'goldenrod') and
        (i_units = 'Carton' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'coral') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'aquamarine') and 
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'rose') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'cyan') and
        (i_units = 'Pound' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'cream') and
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
