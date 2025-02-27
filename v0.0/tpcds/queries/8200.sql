
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 899 and 899+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'hot') and 
        (i_units = 'Cup' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'black') and
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'ghost') and
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'linen') and
        (i_units = 'Unknown' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'cornsilk') and 
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'peach') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'grey') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
