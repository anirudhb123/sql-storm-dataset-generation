
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 884 and 884+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'lime') and 
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'dodger') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'snow') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'cream') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'metallic') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'almond') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'ghost') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'burnished') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
