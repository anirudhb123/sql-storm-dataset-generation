
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 940 and 940+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'azure') and 
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'chocolate') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'papaya') and
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'rose') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'ghost') and 
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'rosy') and
        (i_units = 'Ton' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'lawn') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'magenta') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
