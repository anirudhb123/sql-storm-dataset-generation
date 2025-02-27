
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 997 and 997+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'frosted') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'khaki') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'pink') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'cornsilk') and 
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'orchid' or i_color = 'smoke') and
        (i_units = 'Box' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'powder') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'lime') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
