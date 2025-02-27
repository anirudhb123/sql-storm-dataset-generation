
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 710 and 710+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'dodger') and 
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'tomato') and
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'purple') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'forest') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'saddle') and 
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'almond') and
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'papaya') and
        (i_units = 'Pound' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'floral') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
