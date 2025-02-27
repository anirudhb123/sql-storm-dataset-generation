
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 755 and 755+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'dim') and 
        (i_units = 'Unknown' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'gainsboro') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'deep') and
        (i_units = 'Gram' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'frosted') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'coral') and 
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'ghost') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'linen') and
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'almond') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
