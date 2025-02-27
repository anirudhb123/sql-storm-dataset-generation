
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 669 and 669+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'goldenrod') and 
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'saddle') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'lace') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'dark') and
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'burnished') and 
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'snow') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'puff') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'yellow') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
