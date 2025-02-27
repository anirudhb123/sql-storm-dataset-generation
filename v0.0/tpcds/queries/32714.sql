
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 737 and 737+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'gainsboro') and 
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'drab') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'maroon') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'lavender') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'cyan') and 
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'deep') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'red') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'cream') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
