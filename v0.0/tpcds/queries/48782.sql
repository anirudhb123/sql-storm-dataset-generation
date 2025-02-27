
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 740 and 740+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'green') and 
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'sandy' or i_color = 'medium') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'honeydew') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'lime') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'peru') and 
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'cream') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'floral') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'cyan') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
