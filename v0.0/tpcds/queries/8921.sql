
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 729 and 729+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'indian') and 
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'moccasin') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'orange') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'hot') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'magenta') and 
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'sienna') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'dim') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'plum') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
