
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 695 and 695+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'black') and 
        (i_units = 'Tsp' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'orchid') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'sandy') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'linen') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'thistle') and 
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'papaya') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'royal') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'midnight') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
