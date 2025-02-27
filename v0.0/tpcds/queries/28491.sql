
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 946 and 946+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'navajo') and 
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'burnished') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'indian') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'orchid') and
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'lace') and 
        (i_units = 'Pallet' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'blush') and
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'cyan') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
