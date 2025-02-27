
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 900 and 900+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'frosted') and 
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'white') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'wheat') and
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'spring') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'almond') and 
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'drab') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'snow') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'bisque') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
