
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 897 and 897+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'lime') and 
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'puff') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'thistle') and
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'grey') and
        (i_units = 'N/A' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'blush') and 
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'dim') and
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'pink') and
        (i_units = 'Cup' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'peach') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
