
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 809 and 809+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'tan') and 
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'frosted') and
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'forest') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'drab') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'lawn') and 
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'seashell') and
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'ghost') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'firebrick') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
