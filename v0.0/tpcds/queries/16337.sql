
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 869 and 869+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'blue') and 
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'tan') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'gainsboro') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'slate') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'smoke') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'ghost') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'red') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'orchid') and
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
