
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 883 and 883+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'slate') and 
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'khaki') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'floral') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'blush') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'sandy') and 
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'metallic') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'ghost') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'maroon') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
