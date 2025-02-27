
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 983 and 983+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'royal') and 
        (i_units = 'Cup' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'goldenrod') and
        (i_units = 'Dram' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'firebrick') and
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'blush') and
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'dodger') and 
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'maroon') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'tomato') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'orange') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
