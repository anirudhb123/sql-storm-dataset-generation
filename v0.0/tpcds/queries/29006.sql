
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 667 and 667+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'cornflower') and 
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'brown') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'almond') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'black') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'ivory') and 
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'violet') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'magenta') and
        (i_units = 'Bundle' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'antique') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
