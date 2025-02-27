
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 680 and 680+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'blue') and 
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'sienna') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'puff') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'yellow') and
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'powder') and 
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'orchid' or i_color = 'ivory') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'grey') and
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'hot') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
