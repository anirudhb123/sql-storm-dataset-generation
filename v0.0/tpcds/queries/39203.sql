
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 695 and 695+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'grey') and 
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'seashell') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'firebrick') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'aquamarine') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'salmon') and 
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'maroon') and
        (i_units = 'Ounce' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'sandy') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'dim') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
