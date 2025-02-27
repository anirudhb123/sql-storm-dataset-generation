
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 728 and 728+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'floral') and 
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'firebrick') and
        (i_units = 'Ounce' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'medium') and
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'misty') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'red') and 
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'wheat') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'deep') and
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'light') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
