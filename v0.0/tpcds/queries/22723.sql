
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 899 and 899+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'violet') and 
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'burnished') and
        (i_units = 'Gross' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'floral') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'orange') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'orchid') and 
        (i_units = 'Cup' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'metallic') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'cyan') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'salmon') and
        (i_units = 'Tbl' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
