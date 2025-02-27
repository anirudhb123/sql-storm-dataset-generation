
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 788 and 788+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'khaki') and 
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'moccasin') and
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burlywood') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'saddle') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'lawn') and 
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'white') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'rosy') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'peach') and
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
