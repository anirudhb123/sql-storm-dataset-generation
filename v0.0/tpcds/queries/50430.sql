
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 752 and 752+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'burlywood') and 
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'steel') and
        (i_units = 'Carton' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'lace') and
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'cream') and
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'dark') and 
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'seashell') and
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'orange') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'mint') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
