
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 668 and 668+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'medium') and 
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'grey') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'tomato') and
        (i_units = 'Dozen' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'cornflower') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'sienna') and 
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'misty') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'mint') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'snow') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
