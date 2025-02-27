
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 858 and 858+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'sienna') and 
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'firebrick') and
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'navy') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'tomato') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'frosted') and 
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'indian') and
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'cornflower') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'navajo') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
