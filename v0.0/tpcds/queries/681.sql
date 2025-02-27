
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 831 and 831+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'olive') and 
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'maroon') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'metallic') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'blush') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'violet') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'gainsboro') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'indian') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'spring') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
