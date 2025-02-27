
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 853 and 853+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'brown') and 
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'forest') and
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'coral') and
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'white') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'smoke') and 
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'orchid') and
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'rose') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
