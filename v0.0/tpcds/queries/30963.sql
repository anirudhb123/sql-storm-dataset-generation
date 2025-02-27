
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 797 and 797+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'forest') and 
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'burnished') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'cream') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'yellow') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'hot') and 
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'purple') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'beige') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'metallic') and
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
