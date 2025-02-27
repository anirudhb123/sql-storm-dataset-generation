
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 886 and 886+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'steel') and 
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'puff') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'khaki') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'peru') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'chocolate') and 
        (i_units = 'Dram' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'misty') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'pink') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'medium') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
