
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 856 and 856+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'grey') and 
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'peru') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'moccasin') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'wheat') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cream' or i_color = 'mint') and 
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'red') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'dim') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'cyan') and
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
