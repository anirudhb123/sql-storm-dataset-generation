
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 943 and 943+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'lawn') and 
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'smoke') and
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'pale') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'bisque') and
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'brown') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'beige') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'cornsilk') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'moccasin') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
