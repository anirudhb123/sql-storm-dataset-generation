
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 870 and 870+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'cyan') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'ivory') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'blush') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'light') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'burlywood') and 
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'chartreuse') and
        (i_units = 'Gram' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'sky') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'yellow') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
