
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 766 and 766+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'chiffon') and 
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'spring') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'chocolate') and
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'ivory') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'burnished') and 
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'orange') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'aquamarine') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'lace') and
        (i_units = 'Gross' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
