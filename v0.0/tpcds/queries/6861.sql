
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 671 and 671+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'magenta') and 
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'light') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'ivory') and
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'snow') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'sky') and 
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'cornsilk') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'lime') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'coral') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
