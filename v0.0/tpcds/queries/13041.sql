
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 845 and 845+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'blush') and 
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'lace') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'burnished') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'aquamarine') and
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'cream') and 
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'green') and
        (i_units = 'Tsp' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'plum') and
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'smoke') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
