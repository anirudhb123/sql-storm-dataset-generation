
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 930 and 930+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'saddle') and 
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'deep') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'spring') and
        (i_units = 'Pallet' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'indian') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'peru') and 
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'light') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'linen') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'sky') and
        (i_units = 'Unknown' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
