
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 956 and 956+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'orange') and 
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'forest') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'ivory') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'maroon') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'white') and 
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'orchid') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'khaki') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'aquamarine') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
