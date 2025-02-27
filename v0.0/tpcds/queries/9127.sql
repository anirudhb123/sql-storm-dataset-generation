
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 919 and 919+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'seashell') and 
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'lemon') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'coral') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'white') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'rosy') and 
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'black') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'deep') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'plum') and
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
