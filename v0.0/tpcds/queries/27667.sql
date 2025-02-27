
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 854 and 854+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'blush') and 
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'orchid' or i_color = 'blanched') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'lime') and
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'chartreuse') and
        (i_units = 'N/A' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'papaya') and 
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'lemon') and
        (i_units = 'Cup' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'sienna') and
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'smoke') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
