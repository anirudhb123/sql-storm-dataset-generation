
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 903 and 903+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'yellow') and 
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'sky') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'turquoise') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'coral') and 
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'firebrick') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'floral') and
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'gainsboro') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
