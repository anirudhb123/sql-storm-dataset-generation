
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 915 and 915+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'seashell') and 
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'hot') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'drab') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'chiffon') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'steel') and 
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'orchid') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'navajo') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'mint') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
