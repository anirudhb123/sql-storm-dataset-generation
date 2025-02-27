
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 929 and 929+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'turquoise') and 
        (i_units = 'Pallet' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'khaki') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'hot') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'pink') and
        (i_units = 'N/A' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'puff') and 
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'saddle') and
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'lime') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'linen') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
