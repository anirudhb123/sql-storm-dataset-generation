
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 754 and 754+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'cream') and 
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'dim') and
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'papaya') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'steel') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'seashell') and 
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'dark') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'chartreuse') and
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'drab') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
