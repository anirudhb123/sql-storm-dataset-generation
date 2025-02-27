
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 984 and 984+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'pink') and 
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'azure') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'cornsilk') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'peru') and
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'hot') and 
        (i_units = 'Unknown' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'turquoise') and
        (i_units = 'Tsp' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'midnight') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'yellow') and
        (i_units = 'Dram' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
