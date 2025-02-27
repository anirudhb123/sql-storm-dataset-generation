
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 769 and 769+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'chartreuse') and 
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'blanched') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'magenta') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'beige') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'almond') and 
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'turquoise' or i_color = 'cyan') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'steel') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'grey') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
