
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 959 and 959+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'spring') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'ivory') and
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'frosted') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'snow') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'almond') and 
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'salmon') and
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'cornsilk') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'plum') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
