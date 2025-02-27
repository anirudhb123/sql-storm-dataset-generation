
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 706 and 706+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'ghost') and 
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'coral') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'medium') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'sky') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'lemon') and 
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'seashell') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'ivory') and
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'lavender') and
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
