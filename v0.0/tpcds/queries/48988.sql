
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 677 and 677+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'green') and 
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'ivory') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'peach') and
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'aquamarine') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'chartreuse') and 
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'blanched') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'purple') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
