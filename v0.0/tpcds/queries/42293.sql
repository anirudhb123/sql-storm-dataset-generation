
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 782 and 782+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'chartreuse') and 
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'bisque') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'blue') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'chocolate') and
        (i_units = 'Ton' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'frosted') and 
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'goldenrod') and
        (i_units = 'Gram' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'lace') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'maroon') and
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
