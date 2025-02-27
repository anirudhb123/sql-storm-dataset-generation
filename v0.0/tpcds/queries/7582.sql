
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 916 and 916+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'black') and 
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'purple') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'honeydew') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'plum') and 
        (i_units = 'Pallet' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'ivory') and
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'spring') and
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'papaya') and
        (i_units = 'Gross' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
