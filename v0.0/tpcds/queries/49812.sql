
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 769 and 769+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'almond') and 
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'lime') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'brown') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'mint') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'seashell') and 
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'gainsboro') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'light') and
        (i_units = 'Bundle' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'medium') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
