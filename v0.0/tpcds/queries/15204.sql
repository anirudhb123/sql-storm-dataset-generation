
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 831 and 831+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'chiffon') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'chartreuse') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'powder') and
        (i_units = 'Oz' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'cyan') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'cornsilk') and 
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'midnight') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'blush') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'peach') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
