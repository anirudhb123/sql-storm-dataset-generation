
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 941 and 941+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'pale') and 
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'pink') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'ivory') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'plum') and
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'cornsilk') and 
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'gainsboro') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'rosy') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'green') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
