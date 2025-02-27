
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 959 and 959+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'grey') and 
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'beige') and
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'blush') and
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'cream') and
        (i_units = 'Each' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'ivory') and 
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'black') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'lavender') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'frosted') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
