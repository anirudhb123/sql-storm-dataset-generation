
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 713 and 713+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'blue') and 
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'light') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'ghost') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'puff') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'hot') and 
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'powder') and
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'bisque') and
        (i_units = 'Tsp' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'slate') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
