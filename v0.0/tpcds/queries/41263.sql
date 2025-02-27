
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 753 and 753+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'medium') and 
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'steel') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'sandy') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'blue') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'khaki') and 
        (i_units = 'Bundle' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'pale') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'misty') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'purple') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
