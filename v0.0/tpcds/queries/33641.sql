
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 838 and 838+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'lemon') and 
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'goldenrod') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'burlywood') and
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'light') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'cornsilk') and 
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'beige') and
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'deep') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'dodger') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
