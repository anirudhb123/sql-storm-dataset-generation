
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 887 and 887+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'sienna') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'pink') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'chiffon') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'green') and 
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'ivory') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'forest') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'rose') and
        (i_units = 'Oz' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
