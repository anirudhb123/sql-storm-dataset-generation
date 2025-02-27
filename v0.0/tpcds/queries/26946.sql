
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 943 and 943+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'cream') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'beige') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'purple') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'tomato') and 
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'puff') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'cornflower') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'powder') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
