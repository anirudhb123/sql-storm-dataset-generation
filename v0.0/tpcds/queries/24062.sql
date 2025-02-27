
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 712 and 712+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'linen') and 
        (i_units = 'Pound' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'spring') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'pale') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'snow') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'burnished') and 
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'powder') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'drab') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'cyan') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
