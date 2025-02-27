
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 696 and 696+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'thistle') and 
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'brown') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'indian') and
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'burlywood') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'mint') and 
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'lemon') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'misty') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'lavender') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
