
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 783 and 783+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'pink') and 
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'peach') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'grey') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'indian') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'royal') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'navajo') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'linen') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'peru') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
