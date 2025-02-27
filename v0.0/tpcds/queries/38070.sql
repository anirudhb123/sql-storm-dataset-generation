
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 738 and 738+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'lime') and 
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'green') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'red') and
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'drab') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'chocolate') and 
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'ghost') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'deep') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'blush') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
