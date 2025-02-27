
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 973 and 973+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'pale') and 
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'navy') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'magenta') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'brown') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'chiffon') and 
        (i_units = 'Unknown' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'moccasin') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'plum') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'red') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
