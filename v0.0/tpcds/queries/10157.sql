
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 948 and 948+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'misty') and 
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'dark') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'chocolate') and
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'cream') and
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'chiffon') and 
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'green') and
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'salmon') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'maroon') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
