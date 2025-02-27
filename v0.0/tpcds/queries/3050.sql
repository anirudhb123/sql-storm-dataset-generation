
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 754 and 754+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'maroon') and 
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'ivory') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'burlywood') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'navajo') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'pale') and 
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'blanched') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'frosted') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'steel') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
