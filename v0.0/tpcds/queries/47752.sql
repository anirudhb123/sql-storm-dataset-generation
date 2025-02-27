
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 711 and 711+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cream' or i_color = 'cornflower') and 
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'lime') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'lemon') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'rose') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'floral') and 
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'gainsboro') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'plum') and
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'lace') and
        (i_units = 'Pallet' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
