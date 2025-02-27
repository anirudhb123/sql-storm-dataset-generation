
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 901 and 901+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'blush') and 
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'orchid') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'puff') and
        (i_units = 'Box' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'blanched') and 
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'olive' or i_color = 'salmon') and
        (i_units = 'Bundle' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'sienna') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'green') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
