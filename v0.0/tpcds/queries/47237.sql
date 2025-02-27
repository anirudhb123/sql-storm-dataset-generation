
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 737 and 737+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lime' or i_color = 'blush') and 
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'floral') and
        (i_units = 'Tsp' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'saddle') and
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'chiffon') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'grey') and 
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'misty') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'coral') and
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'firebrick') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
