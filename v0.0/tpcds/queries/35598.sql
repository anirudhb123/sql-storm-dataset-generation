
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 887 and 887+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'beige') and 
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'dim') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'smoke') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'lime') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'orchid') and 
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'drab') and
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'brown') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'navy') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
