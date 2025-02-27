
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 725 and 725+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'antique') and 
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'snow') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'drab') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'navy') and
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'dim') and 
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'chartreuse') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'olive') and
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'brown') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
