
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 716 and 716+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'almond') and 
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'bisque') and
        (i_units = 'Bunch' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'burnished') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'plum') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'drab') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'metallic') and
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'puff') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'coral') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
