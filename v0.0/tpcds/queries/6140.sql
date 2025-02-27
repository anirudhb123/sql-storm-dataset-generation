
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 841 and 841+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'beige') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'tomato') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'chiffon') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'pink') and
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'orchid') and 
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'dim') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'thistle') and
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
