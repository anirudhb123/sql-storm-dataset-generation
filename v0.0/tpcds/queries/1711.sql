
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 860 and 860+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'honeydew') and 
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'cornsilk') and
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burlywood') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'coral') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'tomato') and 
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'royal') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'burnished') and
        (i_units = 'Each' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'peach') and
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
