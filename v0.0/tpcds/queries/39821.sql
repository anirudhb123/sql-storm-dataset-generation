
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 678 and 678+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'red') and 
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'cornsilk') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'navy') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'lavender') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'smoke') and 
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'lemon') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'blue') and
        (i_units = 'Tsp' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'peach') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
