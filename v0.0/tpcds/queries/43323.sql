
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 811 and 811+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'lime') and 
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'violet') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'white') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'seashell') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'azure') and 
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'deep') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'misty') and
        (i_units = 'N/A' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'forest') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
