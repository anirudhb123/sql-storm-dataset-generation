
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 696 and 696+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'firebrick') and 
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'antique') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'drab') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'moccasin') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'lavender') and 
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'sky') and
        (i_units = 'Ounce' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'peru') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'ghost') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
