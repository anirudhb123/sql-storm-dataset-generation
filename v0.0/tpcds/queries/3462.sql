
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 800 and 800+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'thistle') and 
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'firebrick') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'blue') and
        (i_units = 'Pound' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'drab') and
        (i_units = 'Gross' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'frosted') and 
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'hot') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'goldenrod') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'blanched') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
