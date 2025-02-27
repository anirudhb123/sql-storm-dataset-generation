
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 798 and 798+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'chiffon') and 
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'sandy' or i_color = 'grey') and
        (i_units = 'N/A' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'sky') and
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'orchid') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'forest') and 
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'brown') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'violet') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'navajo') and
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
