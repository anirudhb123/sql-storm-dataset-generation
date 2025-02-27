
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 782 and 782+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'blanched') and 
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'chartreuse') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'burlywood') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'coral') and
        (i_units = 'Bundle' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'lime') and 
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'orange') and
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'blush') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'lawn') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
