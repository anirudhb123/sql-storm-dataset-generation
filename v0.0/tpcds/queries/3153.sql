
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 682 and 682+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'rose') and 
        (i_units = 'Carton' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'maroon') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'indian') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'navy') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'dark') and 
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'seashell') and
        (i_units = 'Gram' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'cream') and
        (i_units = 'Tbl' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'steel') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
