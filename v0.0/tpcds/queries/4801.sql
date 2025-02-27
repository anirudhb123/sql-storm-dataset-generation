
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 947 and 947+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'plum') and 
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'frosted') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'cyan') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'antique') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'drab') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'brown') and
        (i_units = 'Unknown' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'blue') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'misty') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
