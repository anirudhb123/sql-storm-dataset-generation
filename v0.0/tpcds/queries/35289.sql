
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 769 and 769+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'maroon') and 
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'navajo') and
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'pale') and
        (i_units = 'Each' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'misty') and
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'lemon') and 
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'midnight') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'antique') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'sky') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
