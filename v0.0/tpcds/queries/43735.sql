
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 857 and 857+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'rose') and 
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'khaki') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'moccasin') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'burlywood') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'goldenrod') and 
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'navajo') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'wheat') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'coral') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
