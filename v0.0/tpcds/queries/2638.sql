
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 961 and 961+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'turquoise' or i_color = 'blue') and 
        (i_units = 'Dozen' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'floral') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'burlywood') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'brown') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'olive') and 
        (i_units = 'Ounce' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'slate') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'grey') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'sienna') and
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
