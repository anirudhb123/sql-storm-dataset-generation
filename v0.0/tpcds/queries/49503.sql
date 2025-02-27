
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 985 and 985+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'grey') and 
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'beige') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'turquoise') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'smoke') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'forest') and 
        (i_units = 'Box' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'moccasin') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'chocolate') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'floral') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
