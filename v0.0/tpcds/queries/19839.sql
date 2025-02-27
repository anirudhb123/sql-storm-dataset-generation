
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 668 and 668+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'almond') and 
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'orchid') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'aquamarine') and
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'navajo') and
        (i_units = 'Gram' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'khaki') and 
        (i_units = 'Gross' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'ivory') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'drab') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'medium') and
        (i_units = 'Ounce' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
