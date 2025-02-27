
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 723 and 723+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'rosy') and 
        (i_units = 'Carton' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'linen') and
        (i_units = 'Pound' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'spring') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'snow') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'frosted') and 
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'gainsboro') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'mint') and
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'drab') and
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
