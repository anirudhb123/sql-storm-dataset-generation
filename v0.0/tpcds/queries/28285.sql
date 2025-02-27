
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 756 and 756+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'peach') and 
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'moccasin') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'rose') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'indian') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'light') and 
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'lemon') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'antique') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'cornsilk') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
