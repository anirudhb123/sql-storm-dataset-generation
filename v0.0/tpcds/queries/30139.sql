
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 958 and 958+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'blush') and 
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'chartreuse') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'green') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'pale') and
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'deep') and 
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'wheat') and
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'turquoise') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'cornflower') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
