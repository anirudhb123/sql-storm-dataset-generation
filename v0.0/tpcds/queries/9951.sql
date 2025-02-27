
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 758 and 758+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'misty') and 
        (i_units = 'Ton' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'aquamarine') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'bisque') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'peach') and
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'ghost') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'royal') and
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'spring') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'rosy') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
