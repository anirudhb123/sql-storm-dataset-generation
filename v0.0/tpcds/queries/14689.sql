
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 857 and 857+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'sienna') and 
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'hot') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'lavender') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'dark') and
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'cornflower') and 
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'blush') and
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'bisque') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'snow') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
