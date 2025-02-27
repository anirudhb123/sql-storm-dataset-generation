
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 886 and 886+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lime' or i_color = 'chartreuse') and 
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'linen') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'lace') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'steel') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'orchid') and 
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'blanched') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'sienna') and
        (i_units = 'Ounce' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'sky') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
