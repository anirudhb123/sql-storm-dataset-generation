
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 796 and 796+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'burlywood') and 
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'rose') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'cyan') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'almond') and
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'goldenrod') and 
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'brown') and
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'aquamarine') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'violet') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
