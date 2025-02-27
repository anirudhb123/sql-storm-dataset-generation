
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 856 and 856+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'beige') and 
        (i_units = 'Tbl' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'cream') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'red') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'dim') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'dark') and 
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'maroon') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'snow') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
