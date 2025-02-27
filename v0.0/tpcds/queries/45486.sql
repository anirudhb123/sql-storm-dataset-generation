
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 797 and 797+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'tan') and 
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'peru') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'tomato') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'cyan') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'burnished') and 
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'sandy' or i_color = 'chiffon') and
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'thistle') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'smoke') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
