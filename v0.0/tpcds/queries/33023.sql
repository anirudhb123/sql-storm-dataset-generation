
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 855 and 855+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'goldenrod') and 
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'slate') and
        (i_units = 'Gross' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'peru') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'floral') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'lime') and 
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'honeydew') and
        (i_units = 'Ounce' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'chiffon') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'tomato') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
