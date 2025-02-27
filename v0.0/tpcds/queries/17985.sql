
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 800 and 800+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'dark') and 
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'royal') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'turquoise') and
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'chiffon') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'dodger') and 
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'rose' or i_color = 'tan') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'pink') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'cornsilk') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
