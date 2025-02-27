
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 697 and 697+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'cyan') and 
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'almond') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'chocolate') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'burlywood') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'firebrick') and 
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'plum') and
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'orchid') and
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'dodger') and
        (i_units = 'Tsp' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
