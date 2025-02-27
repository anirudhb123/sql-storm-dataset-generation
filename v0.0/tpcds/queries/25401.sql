
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 859 and 859+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'brown') and 
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'beige') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burnished') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'rosy') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'orange') and 
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'grey') and
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'light') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'spring') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
