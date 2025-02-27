
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 799 and 799+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'medium') and 
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'navajo') and
        (i_units = 'Bundle' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'tan') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'royal') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'metallic') and 
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'green') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'cream') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
