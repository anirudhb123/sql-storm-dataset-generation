
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 985 and 985+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'aquamarine') and 
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'turquoise') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'mint') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'navajo') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'grey') and 
        (i_units = 'Tsp' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'spring') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'metallic') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'coral') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
