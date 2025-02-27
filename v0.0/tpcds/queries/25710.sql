
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 724 and 724+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'navy') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'dodger') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'lime') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'misty') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'tomato') and 
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'chocolate') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'almond') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'ghost') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
