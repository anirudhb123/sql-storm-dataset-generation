
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 918 and 918+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'red') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'indian') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'dark') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'mint') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'seashell') and 
        (i_units = 'Gross' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'blanched') and
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'cornflower') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'deep') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
