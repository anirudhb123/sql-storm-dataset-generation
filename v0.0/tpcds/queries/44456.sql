
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 768 and 768+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'medium') and 
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'salmon') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'floral') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'lawn') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'chartreuse') and 
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'gainsboro') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'sky') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'midnight') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
