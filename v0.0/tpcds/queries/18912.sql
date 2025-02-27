
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 901 and 901+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'bisque') and 
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'deep') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'lemon') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'dark') and
        (i_units = 'Pallet' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'turquoise' or i_color = 'purple') and 
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'papaya') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'burlywood') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'cornsilk') and
        (i_units = 'Dram' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
