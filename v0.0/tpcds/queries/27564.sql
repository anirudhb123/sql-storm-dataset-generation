
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 926 and 926+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'rosy') and 
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'drab') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'tan') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'ghost') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'gainsboro') and 
        (i_units = 'Oz' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'slate') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'black') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'lawn') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
