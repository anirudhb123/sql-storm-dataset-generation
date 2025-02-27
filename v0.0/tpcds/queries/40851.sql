
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 707 and 707+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'burnished') and 
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'chiffon') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'navajo') and
        (i_units = 'Dram' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'pale') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'dim') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'green') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'light') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'floral') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
