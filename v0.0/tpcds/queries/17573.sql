
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 754 and 754+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'orchid') and 
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'coral') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'cornsilk') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'peru') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'cornflower') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'misty') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'black') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'beige') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
