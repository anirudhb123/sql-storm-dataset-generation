
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 770 and 770+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'orchid') and 
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'burnished') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'plum') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'aquamarine') and
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'burlywood') and 
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'powder') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'coral') and
        (i_units = 'Box' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'gainsboro') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
