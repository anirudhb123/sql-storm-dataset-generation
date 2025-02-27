
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 945 and 945+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'salmon') and 
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'tomato') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'burnished') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'chocolate') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'dim') and 
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'ivory') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'lace') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'snow') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
