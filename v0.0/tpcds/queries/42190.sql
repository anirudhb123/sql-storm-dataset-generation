
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 854 and 854+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cream' or i_color = 'lemon') and 
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'hot') and
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'yellow') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'lawn') and
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'powder') and 
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'lavender') and
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'blue') and
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'rose') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
