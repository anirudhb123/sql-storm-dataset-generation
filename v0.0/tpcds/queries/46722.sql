
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 682 and 682+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'lemon') and 
        (i_units = 'Tbl' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'almond') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'tomato') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'cream') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'gainsboro') and 
        (i_units = 'Gram' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'cornsilk') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'chartreuse') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'pale') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
