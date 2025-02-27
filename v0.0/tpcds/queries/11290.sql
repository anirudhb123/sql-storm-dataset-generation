
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 986 and 986+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'lawn') and 
        (i_units = 'Cup' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'white') and
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'blue') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'sandy') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'ghost') and 
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'floral') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'royal') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'chiffon') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
