
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 680 and 680+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'blue') and 
        (i_units = 'Ounce' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'cream') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'lime') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'papaya') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'pale') and 
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'floral') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'bisque') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'ghost') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
