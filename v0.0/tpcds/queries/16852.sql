
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 843 and 843+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'maroon') and 
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'red') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'ivory') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'indian') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'lime') and 
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'drab') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'medium') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'orange') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
