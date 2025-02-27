
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 886 and 886+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'royal') and 
        (i_units = 'Tbl' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'pink') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'indian') and
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'rose') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'cream') and 
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'blush') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'snow') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'almond') and
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
