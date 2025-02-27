
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 710 and 710+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'cyan') and 
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'drab') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'sienna') and
        (i_units = 'Tbl' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'forest') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'cornsilk') and 
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'blue') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'firebrick') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'maroon') and
        (i_units = 'N/A' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
