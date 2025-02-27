
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 874 and 874+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'light') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'cornsilk') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'burlywood') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'aquamarine') and
        (i_units = 'Ton' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'firebrick') and 
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'slate') and
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'grey') and
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'coral') and
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
