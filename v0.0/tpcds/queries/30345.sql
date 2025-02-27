
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 814 and 814+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'lace') and 
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'brown') and
        (i_units = 'Dram' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'seashell') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'salmon') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'white') and 
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'lemon') and
        (i_units = 'Gram' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'turquoise') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'tan') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
