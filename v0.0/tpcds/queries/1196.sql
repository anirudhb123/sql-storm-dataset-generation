
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 886 and 886+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'pale') and 
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'chartreuse') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'misty') and
        (i_units = 'Pallet' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'smoke') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'slate') and 
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'hot') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'navy') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'lime') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
