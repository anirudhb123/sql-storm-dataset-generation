
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 769 and 769+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'firebrick') and 
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'burlywood') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'cream') and
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'moccasin') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'black') and 
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'bisque') and
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'sandy') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'dim') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
