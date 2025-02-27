
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 816 and 816+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'thistle') and 
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'pink') and
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'chiffon') and
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'drab') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'lime') and 
        (i_units = 'Pound' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'lawn') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'metallic') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'black') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
