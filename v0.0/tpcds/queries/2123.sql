
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 987 and 987+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'beige') and 
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'navy') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'seashell') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'black') and
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'lawn') and 
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'forest') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'orchid') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'rose') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
