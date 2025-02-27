
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 902 and 902+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'turquoise' or i_color = 'orange') and 
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'ghost') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'firebrick') and
        (i_units = 'Bundle' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'honeydew') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'purple') and 
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'papaya') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'violet') and
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'burlywood') and
        (i_units = 'Ounce' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
