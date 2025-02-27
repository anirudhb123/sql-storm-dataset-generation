
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 842 and 842+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'aquamarine') and 
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'papaya') and
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'burlywood') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'grey') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'frosted') and 
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'cornflower') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'cornsilk') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'sky') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
