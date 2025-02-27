
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 973 and 973+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'forest') and 
        (i_units = 'Gram' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'azure') and
        (i_units = 'Each' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'sky') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'cornsilk') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'peru') and 
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'cyan') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'blush') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'salmon') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
