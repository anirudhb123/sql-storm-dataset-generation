
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 842 and 842+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'mint') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'green') and
        (i_units = 'Ounce' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'sandy') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'sienna') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'black') and 
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'spring') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'khaki') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'turquoise') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
