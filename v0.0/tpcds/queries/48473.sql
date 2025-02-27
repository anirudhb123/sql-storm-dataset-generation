
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 956 and 956+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'peru') and 
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'firebrick' or i_color = 'snow') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'medium') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'magenta') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'chartreuse') and 
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'black') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'rosy') and
        (i_units = 'Box' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
