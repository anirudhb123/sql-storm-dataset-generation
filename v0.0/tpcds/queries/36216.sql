
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 870 and 870+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'azure' or i_color = 'floral') and 
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'firebrick') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'dodger') and
        (i_units = 'Box' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'violet') and
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'lawn') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'navajo') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'maroon') and
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'powder') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
