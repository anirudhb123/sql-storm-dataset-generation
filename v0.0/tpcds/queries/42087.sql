
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 926 and 926+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'dark') and 
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'coral') and
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'honeydew') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'aquamarine') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'chartreuse') and 
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'maroon') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'blue') and
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'light') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
