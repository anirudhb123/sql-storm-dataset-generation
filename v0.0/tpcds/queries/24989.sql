
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 813 and 813+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'bisque') and 
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'lime') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'purple') and
        (i_units = 'Carton' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'magenta') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'lawn') and 
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'forest') and
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'orange') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'azure') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
