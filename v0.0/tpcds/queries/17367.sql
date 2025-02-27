
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 898 and 898+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'saddle') and 
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'medium') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'aquamarine') and
        (i_units = 'Ounce' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'honeydew') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'almond') and 
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'ivory') and
        (i_units = 'Tsp' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'floral') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'maroon') and
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
