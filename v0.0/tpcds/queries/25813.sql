
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 986 and 986+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'maroon') and 
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'beige') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'powder') and
        (i_units = 'Pound' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'navy') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'tan') and
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'lemon') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'steel') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
