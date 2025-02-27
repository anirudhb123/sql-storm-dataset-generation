
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 898 and 898+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'brown') and 
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'mint' or i_color = 'blue') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'beige') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'peru') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'wheat' or i_color = 'cornsilk') and 
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'coral') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'floral') and
        (i_units = 'Dram' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'moccasin') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
