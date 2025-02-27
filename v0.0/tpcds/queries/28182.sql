
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 828 and 828+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'royal') and 
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'grey') and
        (i_units = 'Gram' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'deep') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'misty') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'lace') and 
        (i_units = 'Pallet' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'powder') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'purple') and
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'goldenrod') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
