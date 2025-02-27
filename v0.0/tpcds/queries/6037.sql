
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 832 and 832+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'turquoise' or i_color = 'salmon') and 
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'navy') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'blush') and
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'rose') and
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'almond') and 
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'ivory') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'metallic') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'sandy') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
