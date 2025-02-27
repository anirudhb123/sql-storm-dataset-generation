
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 989 and 989+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'chocolate') and 
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'cornflower') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'blue') and
        (i_units = 'Each' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'misty') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'blanched') and 
        (i_units = 'Unknown' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'powder') and
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'aquamarine') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'gainsboro') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
