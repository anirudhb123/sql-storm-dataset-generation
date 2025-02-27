
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 915 and 915+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'aquamarine') and 
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'ghost') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'blush') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'gainsboro') and
        (i_units = 'Bundle' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'mint') and 
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'wheat') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'sandy') and
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'white') and
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
