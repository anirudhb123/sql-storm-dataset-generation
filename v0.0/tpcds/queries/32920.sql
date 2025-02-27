
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 927 and 927+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'dark') and 
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'plum') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'lime') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'olive') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'azure') and 
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'orchid' or i_color = 'burnished') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'purple') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'thistle') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
