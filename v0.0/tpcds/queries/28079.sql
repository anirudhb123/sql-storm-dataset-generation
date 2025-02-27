
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 900 and 900+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'red') and 
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'plum') and
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'cornflower') and
        (i_units = 'Bunch' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'chiffon') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'blanched') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'orchid' or i_color = 'floral') and
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'blue') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'goldenrod') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
