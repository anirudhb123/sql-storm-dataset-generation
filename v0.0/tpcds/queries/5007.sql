
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 803 and 803+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'brown') and 
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'yellow') and
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'sky') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'navy') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'drab') and 
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'forest') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'ghost') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'red') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
