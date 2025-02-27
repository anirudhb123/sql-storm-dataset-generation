
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 696 and 696+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'floral') and 
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'lawn') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'drab') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'olive') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'dodger') and 
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'green') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'magenta') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'indian') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
