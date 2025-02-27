
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 972 and 972+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'magenta') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'wheat') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'seashell') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'lawn') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'burlywood') and 
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'cyan') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'turquoise') and
        (i_units = 'Ounce' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'medium') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
