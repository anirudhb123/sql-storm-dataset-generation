
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 990 and 990+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'dark') and 
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'powder') and
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'goldenrod') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'orange') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'salmon') and 
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'steel') and
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'mint') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'green') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
