
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 681 and 681+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'almond') and 
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'antique') and
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'blush') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'deep') and
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'lemon') and 
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'salmon') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'ghost') and
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'wheat') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
