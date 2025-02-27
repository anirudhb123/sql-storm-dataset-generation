
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 838 and 838+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'azure') and 
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'dark') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'tomato') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'blue') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'peru') and 
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'gainsboro') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'medium') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'burnished') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
