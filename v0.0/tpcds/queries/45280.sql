
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 941 and 941+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'saddle') and 
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'dim') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'cyan') and
        (i_units = 'Unknown' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'hot') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'seashell') and 
        (i_units = 'Pallet' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'blanched') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'deep') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'khaki') and
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
