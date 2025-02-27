
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 784 and 784+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'lime') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'burlywood') and
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'ghost') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'dodger') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'moccasin') and 
        (i_units = 'Gross' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'cyan') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'goldenrod') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'navajo') and
        (i_units = 'Cup' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
