
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 697 and 697+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'light') and 
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'brown') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'dim') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'puff') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'ghost') and 
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'deep') and
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'yellow') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'frosted') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
