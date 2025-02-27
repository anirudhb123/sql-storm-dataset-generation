
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 765 and 765+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'firebrick') and 
        (i_units = 'Pound' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'green') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'smoke') and
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'lemon') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'dark') and 
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'lime') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'beige') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'ivory') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
