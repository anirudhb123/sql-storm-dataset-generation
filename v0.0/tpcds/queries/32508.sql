
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 800 and 800+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'bisque') and 
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'chartreuse') and
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'ivory') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'gainsboro') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'dodger') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'royal') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'sienna') and
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'grey') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
