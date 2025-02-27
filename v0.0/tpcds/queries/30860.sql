
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 869 and 869+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'brown') and 
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'royal') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'violet') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'gainsboro') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'navajo') and 
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'cyan') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'almond') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'dodger') and
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
