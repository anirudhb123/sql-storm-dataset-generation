
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 773 and 773+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'medium') and 
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'blue') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'light') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'violet') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'khaki') and 
        (i_units = 'Gram' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'powder') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'bisque') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'hot') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
