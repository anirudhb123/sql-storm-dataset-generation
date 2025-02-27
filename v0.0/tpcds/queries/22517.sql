
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 709 and 709+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'azure') and 
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'almond') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'green') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'chiffon') and
        (i_units = 'Gram' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'lime') and 
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'tan') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'lace') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'yellow') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
