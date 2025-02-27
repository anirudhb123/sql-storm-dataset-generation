
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 711 and 711+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'tomato') and 
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'brown') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'coral') and
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'lavender') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'salmon') and 
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'almond') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'rosy') and
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'cream') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
