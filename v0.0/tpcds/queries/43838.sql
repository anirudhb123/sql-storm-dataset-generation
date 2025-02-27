
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 866 and 866+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'chiffon') and 
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'navy') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'olive') and
        (i_units = 'Dozen' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'linen') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'khaki') and 
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'seashell') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'lime') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'cornsilk') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
