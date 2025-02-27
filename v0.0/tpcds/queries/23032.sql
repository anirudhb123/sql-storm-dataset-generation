
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 683 and 683+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'moccasin') and 
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'purple') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'honeydew') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'medium') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'metallic') and 
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'orchid') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'navajo') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'magenta') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
