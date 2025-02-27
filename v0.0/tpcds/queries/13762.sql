
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 756 and 756+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'brown') and 
        (i_units = 'Unknown' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'antique') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'khaki') and
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'lavender') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'ghost') and 
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'dim') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'frosted') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'puff') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
