
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 753 and 753+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'rosy') and 
        (i_units = 'Lb' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'navajo') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'light') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'puff') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'white') and 
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'cream') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'plum') and
        (i_units = 'Ounce' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'orange') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
