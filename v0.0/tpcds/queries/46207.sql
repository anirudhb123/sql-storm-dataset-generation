
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 708 and 708+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'salmon') and 
        (i_units = 'Pallet' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'white') and
        (i_units = 'Ton' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'frosted') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'plum') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'light') and 
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'chiffon') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'midnight') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'lemon') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
