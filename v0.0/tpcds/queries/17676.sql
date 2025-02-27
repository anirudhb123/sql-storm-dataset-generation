
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 682 and 682+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'gainsboro') and 
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'orange') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'lemon') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'grey') and
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'cyan') and 
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'medium') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'misty') and
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'mint') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
