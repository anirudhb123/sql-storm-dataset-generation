
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 957 and 957+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'tan') and 
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'forest') and
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'lemon') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'linen') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'lawn') and 
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'cream') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'cornflower') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'saddle') and
        (i_units = 'Unknown' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
