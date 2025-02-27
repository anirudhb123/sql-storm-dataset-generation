
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 895 and 895+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'moccasin') and 
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'honeydew') and
        (i_units = 'Bundle' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'cornsilk') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'blush') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'lawn') and 
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'dodger') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'ghost') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'violet') and
        (i_units = 'Unknown' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
