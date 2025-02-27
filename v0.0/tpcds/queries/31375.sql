
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 843 and 843+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'azure' or i_color = 'chartreuse') and 
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'misty') and
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'sandy') and
        (i_units = 'Unknown' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'brown') and
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'bisque') and 
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'rose') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'beige') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'lavender') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
