
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 960 and 960+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'misty') and 
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'brown') and
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'light') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'yellow') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'antique') and 
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'ivory') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'lavender') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'rose') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
