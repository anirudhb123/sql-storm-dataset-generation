
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 771 and 771+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lime' or i_color = 'indian') and 
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'cyan') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'lace') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'salmon') and
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'firebrick') and 
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'powder') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'dark') and
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'pink') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
