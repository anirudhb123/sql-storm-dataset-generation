
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 812 and 812+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'smoke') and 
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'pale') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'burlywood') and
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'deep') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'dark') and 
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'firebrick') and
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'maroon') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'brown') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
