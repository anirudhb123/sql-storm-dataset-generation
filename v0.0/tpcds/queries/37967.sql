
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 810 and 810+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'blue') and 
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'orchid') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'orange') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'cream') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'lemon') and 
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'forest') and
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'mint') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'hot') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
