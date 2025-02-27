
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 974 and 974+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'bisque') and 
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'chocolate') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'grey') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'dark') and
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cream' or i_color = 'navy') and 
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'maroon') and
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'white') and
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'light') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
