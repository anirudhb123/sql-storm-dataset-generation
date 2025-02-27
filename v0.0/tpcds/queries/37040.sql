
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 709 and 709+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'aquamarine') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'dodger') and
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'chocolate') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'ghost') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'lime') and 
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'rosy') and
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'peach') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'rose') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
