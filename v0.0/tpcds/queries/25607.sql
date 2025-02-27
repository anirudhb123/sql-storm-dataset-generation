
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 796 and 796+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'olive') and 
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'green') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'light') and
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'brown') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'burlywood') and 
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'peru') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'hot') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'spring') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
