
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 728 and 728+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'navy') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'chartreuse') and
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'antique') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'ivory') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'dark') and 
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'salmon') and
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'aquamarine') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'saddle') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
