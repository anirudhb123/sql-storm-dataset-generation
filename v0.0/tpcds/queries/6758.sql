
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 743 and 743+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'grey') and 
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'seashell') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'plum') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'lace') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'brown') and 
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'thistle') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'powder') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'ivory') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
