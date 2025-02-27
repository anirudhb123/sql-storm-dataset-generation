
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 814 and 814+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'dark') and 
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'seashell') and
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'lime') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'honeydew') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'papaya') and 
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'olive') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'wheat') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'misty') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
