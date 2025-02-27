
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 974 and 974+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'ivory') and 
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'blue') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'forest') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'misty') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'yellow') and 
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'slate') and
        (i_units = 'Case' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'goldenrod') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'burlywood') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
