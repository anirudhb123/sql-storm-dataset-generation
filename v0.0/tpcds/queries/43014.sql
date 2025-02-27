
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 693 and 693+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'orange') and 
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'misty') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'rosy') and
        (i_units = 'Gross' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'bisque') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'peach') and 
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'drab') and
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'lawn') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'navy') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
