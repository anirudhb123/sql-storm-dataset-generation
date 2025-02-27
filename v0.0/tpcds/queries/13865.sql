
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 684 and 684+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'bisque') and 
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'floral') and
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'rosy') and
        (i_units = 'N/A' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'midnight') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'brown') and 
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'green') and
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'burlywood') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'puff') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
