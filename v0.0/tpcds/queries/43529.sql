
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 667 and 667+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'salmon') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'aquamarine') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'lawn') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'firebrick') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'light') and 
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'coral') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'lime') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'goldenrod') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
