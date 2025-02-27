
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 913 and 913+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'burnished') and 
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'forest' or i_color = 'powder') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'cream') and
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'puff') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'firebrick') and 
        (i_units = 'Lb' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'orchid') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'light') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'almond') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
