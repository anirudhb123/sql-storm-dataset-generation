
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 784 and 784+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'bisque') and 
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'firebrick') and
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'burlywood') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'indian') and
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'cream') and 
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'sienna') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'cornflower') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'gainsboro') and
        (i_units = 'Box' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
