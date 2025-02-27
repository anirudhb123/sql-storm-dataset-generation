
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 882 and 882+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'maroon') and 
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'coral') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'brown') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'moccasin') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'lavender') and 
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'sandy' or i_color = 'plum') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'gainsboro') and
        (i_units = 'Tbl' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'steel') and
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
