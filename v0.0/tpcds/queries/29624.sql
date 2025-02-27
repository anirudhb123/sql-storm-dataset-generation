
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 984 and 984+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'antique') and 
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'maroon') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'lavender') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'smoke') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'snow') and 
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'cyan') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'peru') and
        (i_units = 'Tbl' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'misty') and
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
