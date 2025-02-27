
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 889 and 889+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'lemon') and 
        (i_units = 'Oz' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'ghost') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'dim') and
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'deep') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'lime') and 
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'royal') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'sky') and
        (i_units = 'N/A' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'dodger') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
