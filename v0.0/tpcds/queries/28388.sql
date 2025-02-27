
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 684 and 684+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'tan') and 
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'royal') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'goldenrod') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'chartreuse') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'linen') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'cyan') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'rosy') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'burlywood') and
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
