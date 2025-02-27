
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 668 and 668+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'burnished') and 
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'lavender') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'powder') and
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'papaya') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'mint') and 
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'peach') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'floral') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'lemon') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
