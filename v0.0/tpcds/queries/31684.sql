
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 708 and 708+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'green') and 
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'powder') and
        (i_units = 'Tsp' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'yellow') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'firebrick') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'lawn') and 
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'cyan') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'slate') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'snow') and
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
