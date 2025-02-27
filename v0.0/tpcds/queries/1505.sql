
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 670 and 670+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'cyan') and 
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'mint' or i_color = 'plum') and
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'sandy') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'spring') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'deep') and 
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'salmon') and
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'steel') and
        (i_units = 'Unknown' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'lawn') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
