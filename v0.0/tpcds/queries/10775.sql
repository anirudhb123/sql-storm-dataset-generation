
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 931 and 931+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'indian') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'aquamarine') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'lime') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'blush') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'lawn') and 
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'purple') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'metallic') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'cornsilk') and
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
