
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 742 and 742+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'plum') and 
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'lawn') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dim') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'dodger') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'powder') and 
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'lime') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'spring') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'medium') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
