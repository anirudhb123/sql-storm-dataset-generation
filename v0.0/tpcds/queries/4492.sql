
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 829 and 829+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'blue') and 
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'linen') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'snow') and
        (i_units = 'N/A' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'smoke') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'ghost') and 
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'mint' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'orchid') and
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'chocolate') and
        (i_units = 'Gram' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
