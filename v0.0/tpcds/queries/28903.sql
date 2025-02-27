
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 739 and 739+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'orange') and 
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'spring') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'olive') and
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'hot') and
        (i_units = 'Lb' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'purple') and 
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'wheat') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'frosted') and
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'dodger') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
