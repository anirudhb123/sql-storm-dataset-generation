
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 723 and 723+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'peach') and 
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'puff') and
        (i_units = 'Case' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'brown') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'lawn') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'antique') and 
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'frosted') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'moccasin') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'purple') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
