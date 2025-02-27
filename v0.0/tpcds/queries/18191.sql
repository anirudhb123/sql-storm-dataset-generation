
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 990 and 990+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'ivory') and 
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'floral') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'cornflower') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'black') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'almond') and 
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'antique') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'wheat') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'slate') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
