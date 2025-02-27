
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 867 and 867+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'blanched') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'misty') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'lawn') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'turquoise') and
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'dodger') and 
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'hot') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'peach') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'navy') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
