
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 972 and 972+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'orange') and 
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'lace') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'tan') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'burlywood') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'antique') and 
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'rosy') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'peach') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'cyan') and
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
