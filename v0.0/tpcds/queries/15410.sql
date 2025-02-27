
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 768 and 768+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'metallic') and 
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'yellow') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'seashell') and
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'thistle') and
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'sky') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'mint' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'chartreuse') and
        (i_units = 'Gross' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'indian') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
