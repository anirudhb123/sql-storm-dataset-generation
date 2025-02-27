
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 741 and 741+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'indian') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'floral') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'plum') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'lime') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'peach') and 
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'beige') and
        (i_units = 'Tsp' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'navy') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'pale') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
