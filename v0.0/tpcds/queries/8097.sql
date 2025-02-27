
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 890 and 890+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'medium') and 
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'sky') and
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dark') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'spring') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'blush') and 
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'turquoise') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'burnished') and
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'beige') and
        (i_units = 'Lb' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
