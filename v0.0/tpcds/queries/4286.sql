
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 973 and 973+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'smoke') and 
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'grey') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'floral') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'moccasin') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'blue') and 
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'blush') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'bisque') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'lime') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
