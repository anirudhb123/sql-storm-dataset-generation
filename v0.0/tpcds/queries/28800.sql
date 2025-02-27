
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 811 and 811+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'orchid') and 
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'peach') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'mint') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'spring') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'drab') and 
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'cyan') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'navajo') and
        (i_units = 'Gram' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'royal') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
