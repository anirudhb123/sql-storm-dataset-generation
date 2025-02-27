
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 991 and 991+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'navy') and 
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'tomato') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'mint') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'purple') and
        (i_units = 'Bundle' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'maroon') and 
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'sienna') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'gainsboro') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
