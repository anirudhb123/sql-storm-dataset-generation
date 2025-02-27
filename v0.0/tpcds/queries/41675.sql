
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 799 and 799+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'honeydew') and 
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'bisque') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'rosy') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'thistle') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'cornsilk') and 
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'red') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'metallic') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'peach') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
