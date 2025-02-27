
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 871 and 871+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'almond') and 
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'plum') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'goldenrod') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'blanched') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'wheat') and 
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'azure') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'chocolate') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'mint') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
