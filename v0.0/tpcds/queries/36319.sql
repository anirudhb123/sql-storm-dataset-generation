
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 798 and 798+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'cornsilk') and 
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'floral') and
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'frosted') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'blush') and
        (i_units = 'Unknown' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'bisque') and 
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'papaya') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'misty') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'lime') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
