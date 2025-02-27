
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 735 and 735+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'orange') and 
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'blanched') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'tomato') and
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'deep') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'misty') and 
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'chiffon') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'khaki') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'royal') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
