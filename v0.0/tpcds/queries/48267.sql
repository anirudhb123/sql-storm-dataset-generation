
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 766 and 766+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'brown') and 
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'lavender') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'hot') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'burlywood') and
        (i_units = 'Bundle' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'yellow') and 
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'magenta') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'frosted') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'linen') and
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
