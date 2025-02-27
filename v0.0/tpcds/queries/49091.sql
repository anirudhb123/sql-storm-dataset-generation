
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 939 and 939+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'white') and 
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'royal') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'bisque') and
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'burlywood') and
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'purple') and 
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'lemon') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'forest') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'chartreuse') and
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
