
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 841 and 841+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'turquoise') and 
        (i_units = 'Gram' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'seashell') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'tomato') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'spring') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'lemon') and 
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'rosy') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'black') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'smoke') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
