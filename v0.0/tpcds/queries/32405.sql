
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 872 and 872+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'floral') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'olive') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'green') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'chartreuse') and
        (i_units = 'Cup' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'pink') and 
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'lemon') and
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'forest') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'light') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
