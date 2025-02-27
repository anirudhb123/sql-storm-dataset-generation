
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 914 and 914+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'maroon') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'pink') and
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'tan') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'violet') and
        (i_units = 'N/A' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'thistle') and 
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'light') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'firebrick') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'dark') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
