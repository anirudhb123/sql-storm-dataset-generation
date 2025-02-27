
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 916 and 916+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'yellow') and 
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'orchid') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'azure') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'aquamarine') and 
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'honeydew') and
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'beige') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'salmon') and
        (i_units = 'Tsp' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
