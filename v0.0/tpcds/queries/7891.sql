
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 700 and 700+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'dark') and 
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'ghost') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'peach') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'seashell') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'navy') and 
        (i_units = 'Tsp' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'burnished') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'rose') and
        (i_units = 'Oz' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'thistle') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
