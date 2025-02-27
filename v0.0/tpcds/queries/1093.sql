
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 958 and 958+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'ivory') and 
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'hot') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'dodger') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'chartreuse') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'green') and 
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'papaya') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'cyan') and
        (i_units = 'Gram' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'ghost') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
