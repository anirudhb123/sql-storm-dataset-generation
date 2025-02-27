
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 870 and 870+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'royal') and 
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'dark') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'cornflower') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'navy') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'seashell') and 
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'tan') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'forest') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'peru') and
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
