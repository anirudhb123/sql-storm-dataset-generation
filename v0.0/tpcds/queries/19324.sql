
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 947 and 947+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'dodger') and 
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'sky') and
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'saddle') and
        (i_units = 'Tbl' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'hot') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'dim') and 
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'steel') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'lime') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'black') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
