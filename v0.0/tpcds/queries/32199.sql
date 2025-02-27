
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 682 and 682+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'spring') and 
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'misty') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'sky') and
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'snow') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'rosy') and 
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'cyan') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'chiffon') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'goldenrod') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
