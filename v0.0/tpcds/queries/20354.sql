
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 976 and 976+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'antique') and 
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'puff') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'chartreuse') and
        (i_units = 'Pound' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'tan') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'khaki') and 
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'rose') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'rosy') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'smoke') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
