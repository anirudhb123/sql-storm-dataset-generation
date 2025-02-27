
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 786 and 786+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'forest') and 
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'cream') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'grey') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'orange') and
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'spring') and 
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'bisque') and
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'chartreuse') and
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'white') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
