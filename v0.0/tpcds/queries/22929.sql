
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 755 and 755+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'dim') and 
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'bisque') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'misty') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'gainsboro') and
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'rose') and 
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'tan') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'linen') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'ghost') and
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
