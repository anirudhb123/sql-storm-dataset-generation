
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 900 and 900+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'cornflower') and 
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'blue') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'snow') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'wheat') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'firebrick') and 
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'white') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'cyan') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'dim') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
