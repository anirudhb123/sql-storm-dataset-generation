
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 896 and 896+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'sandy') and 
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'blue') and
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'yellow') and
        (i_units = 'Bunch' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'peru') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'navy') and 
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'lime') and
        (i_units = 'Gross' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'goldenrod') and
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'seashell') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
