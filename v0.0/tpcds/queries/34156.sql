
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 812 and 812+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'peru') and 
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'rose') and
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'gainsboro') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'aquamarine') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'orchid') and 
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'ivory') and
        (i_units = 'Pound' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'papaya') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'dark') and
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
