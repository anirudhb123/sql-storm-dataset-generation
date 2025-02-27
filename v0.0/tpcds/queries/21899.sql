
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 726 and 726+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'plum') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'snow') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'moccasin') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'light') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'slate') and 
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'ivory') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'violet') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'frosted') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
