
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 757 and 757+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'goldenrod') and 
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'peach') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'cyan') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'midnight') and
        (i_units = 'Dram' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'light') and 
        (i_units = 'Oz' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'chocolate') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'misty') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'navajo') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
