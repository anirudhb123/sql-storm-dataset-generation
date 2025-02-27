
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 933 and 933+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'hot') and 
        (i_units = 'Unknown' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'cyan') and
        (i_units = 'N/A' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'smoke') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'chartreuse') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'cream') and 
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'coral') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'chocolate') and
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'rosy') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
