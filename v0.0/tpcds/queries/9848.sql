
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 830 and 830+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'grey') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'yellow') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'spring') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'medium') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'light') and 
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'cyan') and
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'tomato') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'azure') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
