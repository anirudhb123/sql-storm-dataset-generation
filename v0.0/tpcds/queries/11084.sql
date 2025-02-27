
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 715 and 715+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'purple') and 
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'beige') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'pale') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'spring') and
        (i_units = 'N/A' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'ivory') and 
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'navajo') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'blush') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'misty') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
