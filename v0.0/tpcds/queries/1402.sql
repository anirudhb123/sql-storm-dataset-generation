
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 742 and 742+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'burnished') and 
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'yellow') and
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'forest') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'pale') and
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'khaki') and 
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'rose') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'rosy') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'dark') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
