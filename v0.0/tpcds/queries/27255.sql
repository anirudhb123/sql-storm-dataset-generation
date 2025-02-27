
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 727 and 727+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'cyan') and 
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'olive' or i_color = 'blush') and
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'red') and
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'green') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'black') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'medium') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'brown') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'mint') and
        (i_units = 'Gross' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
