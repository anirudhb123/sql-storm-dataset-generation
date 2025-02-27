
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 725 and 725+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'goldenrod') and 
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'honeydew') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'misty') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'chiffon') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'spring') and 
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'turquoise') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'peru') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'blush') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
