
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 679 and 679+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'navajo') and 
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'beige') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'steel') and
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'brown') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'gainsboro') and 
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'chocolate') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'sandy') and
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'green') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
