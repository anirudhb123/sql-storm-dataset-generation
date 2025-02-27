
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 783 and 783+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'turquoise') and 
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'burnished') and
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'maroon') and
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'cornsilk') and
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'navajo') and 
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'misty') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'smoke') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'yellow') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
