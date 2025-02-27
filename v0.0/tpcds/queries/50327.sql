
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 824 and 824+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'olive') and 
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'violet') and
        (i_units = 'Case' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'tomato') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'burlywood') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'dark') and 
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'blue') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'midnight') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'spring') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
