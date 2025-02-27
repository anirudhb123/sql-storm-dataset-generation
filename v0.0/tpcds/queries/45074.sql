
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 751 and 751+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'khaki') and 
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'forest') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'dodger') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'black') and
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'mint') and 
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'azure') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'cyan') and
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
