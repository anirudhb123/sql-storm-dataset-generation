
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 958 and 958+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'firebrick') and 
        (i_units = 'Ton' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'linen') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'rosy') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'wheat') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'moccasin') and 
        (i_units = 'Dram' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'chiffon') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'papaya') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'medium') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
