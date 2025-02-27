
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 787 and 787+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rose' or i_color = 'chocolate') and 
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'dim') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'grey') and
        (i_units = 'Tbl' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'pink') and
        (i_units = 'Oz' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'turquoise') and 
        (i_units = 'Gross' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'green') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'khaki') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'beige') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
