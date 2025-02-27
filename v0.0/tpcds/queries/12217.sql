
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 753 and 753+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'almond') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'chocolate') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'brown') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'olive') and 
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'peach') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'tomato') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'light') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
