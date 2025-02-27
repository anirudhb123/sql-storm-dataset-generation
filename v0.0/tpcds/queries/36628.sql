
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 916 and 916+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'burnished') and 
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'smoke') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'light') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'dark') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'magenta') and 
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'cream') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'sky') and
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'linen') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
