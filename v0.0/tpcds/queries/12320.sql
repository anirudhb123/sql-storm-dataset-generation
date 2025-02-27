
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 681 and 681+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'medium') and 
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'blush') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'royal') and
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'dim') and
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'forest') and 
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'light') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'cornflower') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'red') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
