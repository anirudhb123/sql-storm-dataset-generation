
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 783 and 783+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'ivory') and 
        (i_units = 'Tbl' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'beige') and
        (i_units = 'Carton' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'purple') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'sky') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'cyan') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'tan') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'aquamarine') and
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'grey') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
