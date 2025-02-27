
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 841 and 841+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'floral') and 
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'tomato') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'bisque') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'maroon') and
        (i_units = 'Gross' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'saddle') and 
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'misty') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'lace') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'beige') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
